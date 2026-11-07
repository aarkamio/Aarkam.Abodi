<#
.SYNOPSIS
    Rokka Abodi Node Agent — Automated Production Installation & Bootstrap Script for Windows Server.

.DESCRIPTION
    Automates the production deployment of the Rokka Abodi Storage & Diagnostics Node Agent on
    Windows Server 2022 / Windows Server 2025 (and Windows 10/11 Enterprise for evaluation).
    Abodi registers exclusively with the Rokka Storage Coordinator (Zero dependency on Aarkam.IO).
    - Validates Administrator privileges, OS build, WMI/CIM Storage Management subsystem, and RAM.
    - Verifies or installs the .NET 10.0 ASP.NET Core Runtime.
    - Creates the isolated directory structure under C:\Program Files\Aarkam\Abodi and C:\ProgramData\Rokka.
    - Enforces strict NTFS ACLs (disabling inheritance) on C:\ProgramData\Rokka\Security to protect
      the ECDSA P-256 private key (node-identity.key) and single-use bootstrap token.
    - Provisions the single-use Rokka enrollment token (ET1.<hex>) and scrubs any source token file.
    - Generates appsettings.Production.json and configures Windows Defender Firewall rules.
    - Registers and starts the Rokka.Abodi.Agent Windows Service with automatic failure recovery.

.PARAMETER NodeCode
    Unique identifier for this storage node (defaults to $env:COMPUTERNAME).

.PARAMETER RokkaUrl
    Rokka Coordinator endpoint (defaults to "https://rokka-coordinator.aarkam:57774").
    Supports sovereign cluster DNS ('https://rokka-coordinator.aarkam:57774'), standard port 443 ('https://rokka-coordinator.aarkam' or 'https://rokka-coordinator.aarkam:443'),
    local edge/dev ('https://localhost:57774'), or any custom on-premises IP/path ('https://10.20.0.10:57774', 'https://storage.internal.net/rokka').

.PARAMETER TrustDomain
    Zero-Trust SPIFFE trust domain (default: "rokka.cluster").

.PARAMETER EnrollmentToken
    Single-use bootstrap token (ET1.<hex>) issued by Rokka (or via 'am node token create' routed through Rokka).

.PARAMETER TokenFile
    Path to a temporary file containing the single-use enrollment token (automatically deleted after reading).

.PARAMETER SourcePath
    Path to pre-published Abodi binaries or the repository root containing src\Abodi\Abodi.csproj.

.PARAMETER StorageDir
    Dedicated non-OS storage directory (e.g., "D:\rokka_storage"). Defaults to first non-C: fixed drive if available.

.PARAMETER AllowOsPartition
    Switch to permit storage placement on the C: operating system partition (evaluation/development only).

.PARAMETER SkipFirewall
    Switch to skip Windows Defender Firewall rule creation.

.EXAMPLE
    .\install-abodi.ps1 -NodeCode "NODE-WIN-042" -RokkaUrl "https://rokka-coordinator.aarkam:57774" -EnrollmentToken "ET1.9f86d0..." -StorageDir "D:\rokka_storage"

.EXAMPLE
    .\install-abodi.ps1 -NodeCode "NODE-WIN-042" -RokkaUrl "https://rokka-coordinator.aarkam" -EnrollmentToken "ET1.9f86d0..." -StorageDir "D:\rokka_storage"

.EXAMPLE
    .\install-abodi.ps1 -NodeCode "NODE-DEV-001" -RokkaUrl "https://localhost:57774" -EnrollmentToken "ET1.9f86d0..." -AllowOsPartition
#>

[CmdletBinding()]
param(
    [string]$NodeCode = $env:COMPUTERNAME,
    [string]$RokkaUrl = "https://rokka-coordinator.aarkam:57774",
    [string]$TrustDomain = "rokka.cluster",
    [string]$EnrollmentToken = "",
    [string]$TokenFile = "",
    [string]$SourcePath = "",
    [string]$InstallDir = "C:\Program Files\Aarkam\Abodi",
    [string]$StorageDir = "",
    [switch]$AllowOsPartition,
    [switch]$SkipFirewall
)

$ErrorActionPreference = "Stop"

function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Message) Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err   { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# ------------------------------------------------------------------------------
# Normalize and Validate Rokka Coordinator URL & On-Premises Path
# ------------------------------------------------------------------------------
$RokkaUrl = $RokkaUrl.Trim()
if (-not $RokkaUrl.StartsWith("http://", [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $RokkaUrl.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
    $RokkaUrl = "https://$RokkaUrl"
}

try {
    $parsedUri = [System.Uri]$RokkaUrl
    $effectivePort = if ($parsedUri.Port -gt 0) { $parsedUri.Port } elseif ($parsedUri.Scheme -eq "https") { 443 } else { 80 }
    Write-Info "Target Rokka Coordinator: $RokkaUrl (Host: $($parsedUri.Host), Port: $effectivePort, Path: $($parsedUri.AbsolutePath))"
} catch {
    Write-Err "Invalid Rokka Coordinator URL: '$RokkaUrl'. Must be a valid on-premises URI or hostname (e.g. 'https://rokka-coordinator.aarkam:57774', 'https://rokka-coordinator.aarkam', 'https://10.20.0.10:57774', 'https://localhost:57774')."
    exit 1
}

# ------------------------------------------------------------------------------
# Step 1: Verify Administrator Privileges & OS Prerequisites
# ------------------------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "This installer must be run from an elevated PowerShell prompt (Run as Administrator)."
    exit 1
}

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$totalRamMB = [math]::Round($osInfo.TotalVisibleMemorySize / 1024)
Write-Info "Detected OS: $($osInfo.Caption) (Build $($osInfo.BuildNumber)) | RAM: $totalRamMB MB"

if ($totalRamMB -lt 1800) {
    Write-Warn "Host has $totalRamMB MB RAM. Minimum required is 2,048 MB (16,384 MB+ recommended for production storage nodes)."
} else {
    Write-Ok "Memory check passed ($totalRamMB MB available)."
}

# Verify Windows Storage Management WMI namespace (MSFT_PhysicalDisk) used by Abodi Windows collectors
try {
    $physDisks = Get-CimInstance -Namespace "root\Microsoft\Windows\Storage" -ClassName "MSFT_PhysicalDisk" -ErrorAction Stop
    Write-Ok "Verified Windows Storage Management WMI provider ($($physDisks.Count) physical disk(s) visible)."
} catch {
    Write-Err "Windows Storage Management WMI namespace (root\Microsoft\Windows\Storage) is unavailable: $_"
    exit 1
}

# Verify Windows Time Service (w32time) for mTLS clock skew compliance
$w32time = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
if ($null -ne $w32time -and $w32time.Status -ne "Running") {
    Write-Info "Starting Windows Time Service (w32time) for mTLS certificate clock synchronization..."
    Set-Service -Name "w32time" -StartupType Automatic
    Start-Service -Name "w32time"
}

# ------------------------------------------------------------------------------
# Step 2: Verify or Install .NET 10.0 ASP.NET Core Runtime
# ------------------------------------------------------------------------------
function Install-DotNet10Runtime {
    $dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
    if ($null -ne $dotnetCmd) {
        $runtimes = & dotnet --list-runtimes 2>$null
        if ($runtimes -match "Microsoft\.AspNetCore\.App 10\.") {
            Write-Ok ".NET 10.0 ASP.NET Core Runtime is already installed."
            return
        }
    }

    Write-Info "Installing .NET 10.0 ASP.NET Core Runtime via official Microsoft dotnet-install.ps1..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    $installScript = Join-Path $env:TEMP "dotnet-install.ps1"
    Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $installScript -UseBasicParsing

    $dotnetInstallDir = Join-Path $env:ProgramFiles "dotnet"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $installScript -Channel "10.0" -Runtime "aspnetcore" -InstallDir $dotnetInstallDir
    Remove-Item -Path $installScript -Force -ErrorAction SilentlyContinue

    if ($env:Path -notlike "*$dotnetInstallDir*") {
        $env:Path = "$dotnetInstallDir;$env:Path"
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
    }

    $runtimesAfter = & "$dotnetInstallDir\dotnet.exe" --list-runtimes 2>$null
    if ($runtimesAfter -match "Microsoft\.AspNetCore\.App 10\.") {
        Write-Ok ".NET 10.0 ASP.NET Core Runtime installed successfully."
    } else {
        Write-Err "Failed to verify .NET 10.0 ASP.NET Core Runtime after installation."
        exit 1
    }
}

Install-DotNet10Runtime

# ------------------------------------------------------------------------------
# Step 3: Resolve Storage Paths & Enforce Strict NTFS Security ACLs
# ------------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = "C:\Program Files\Aarkam\Abodi"
}
$ProgramData = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)
$RokkaData   = Join-Path $ProgramData "Rokka"
$SecurityDir = Join-Path $RokkaData "Security"
$OutboxDir   = Join-Path $RokkaData "Outbox"
$LogDir      = Join-Path $RokkaData "Logs\Abodi"

if ([string]::IsNullOrWhiteSpace($StorageDir)) {
    # Automatically look for first non-C: fixed volume
    $nonOsVolume = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.DriveLetter -ne 'C' } | Select-Object -First 1
    if ($null -ne $nonOsVolume) {
        $StorageDir = "$($nonOsVolume.DriveLetter):\rokka_storage"
        Write-Info "Auto-selected dedicated non-OS storage volume: $StorageDir"
    } else {
        $StorageDir = Join-Path $RokkaData "Storage"
        if (-not $AllowOsPartition.IsPresent) {
            Write-Warn "No non-C: drive detected. Pass -AllowOsPartition for evaluation/PoC on single-disk systems, or attach a dedicated data disk."
        }
    }
}

foreach ($dir in @($InstallDir, $RokkaData, $SecurityDir, $OutboxDir, $LogDir, $StorageDir)) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Set-RestrictedSecurityDirectoryAcl {
    param([string]$Path)
    $acl = Get-Acl -Path $Path
    # Disable inheritance and remove all inherited permissions
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $acl.Access) {
        $acl.RemoveAccessRule($rule) | Out-Null
    }

    $inheritFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    $propFlags    = [System.Security.AccessControl.PropagationFlags]::None

    # Grant FullControl strictly to SYSTEM and Built-in Administrators
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
    $adminSid  = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)

    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule($systemSid, [System.Security.AccessControl.FileSystemRights]::FullControl, $inheritFlags, $propFlags, [System.Security.AccessControl.AccessControlType]::Allow)
    $adminRule  = New-Object System.Security.AccessControl.FileSystemAccessRule($adminSid,  [System.Security.AccessControl.FileSystemRights]::FullControl, $inheritFlags, $propFlags, [System.Security.AccessControl.AccessControlType]::Allow)

    $acl.AddAccessRule($systemRule)
    $acl.AddAccessRule($adminRule)
    Set-Acl -Path $Path -AclObject $acl
}

Set-RestrictedSecurityDirectoryAcl -Path $SecurityDir
Write-Ok "Configured restricted NTFS ACLs on Zero-Trust vault: $SecurityDir"

# ------------------------------------------------------------------------------
# Step 4: Deploy or Publish Abodi Application Binaries
# ------------------------------------------------------------------------------
$ServiceName = "Rokka.Abodi.Agent"
$existingSvc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $existingSvc -and $existingSvc.Status -eq "Running") {
    Write-Info "Stopping existing $ServiceName service before updating binaries..."
    Stop-Service -Name $ServiceName -Force
    Start-Sleep -Seconds 2
}

if (-not [string]::IsNullOrWhiteSpace($SourcePath)) {
    if (Test-Path (Join-Path $SourcePath "Abodi.dll")) {
        Write-Info "Copying pre-published Abodi binaries from '$SourcePath'..."
        Copy-Item -Path "$SourcePath\*" -Destination $InstallDir -Recurse -Force
    } elseif (Test-Path (Join-Path $SourcePath "src\Abodi\Abodi.csproj")) {
        Write-Info "Publishing Abodi from source repository '$SourcePath'..."
        & dotnet publish (Join-Path $SourcePath "src\Abodi\Abodi.csproj") -c Release -r win-x64 --self-contained false -o $InstallDir
    } else {
        Write-Err "Invalid -SourcePath '$SourcePath'. Expected directory with Abodi.dll or src\Abodi\Abodi.csproj."
        exit 1
    }
} elseif (Test-Path ".\Abodi.dll") {
    Write-Info "Copying Abodi binaries from current directory..."
    Copy-Item -Path ".\*" -Destination $InstallDir -Recurse -Force
} elseif (Test-Path ".\src\Abodi\Abodi.csproj") {
    Write-Info "Publishing Abodi from current repository root..."
    & dotnet publish ".\src\Abodi\Abodi.csproj" -c Release -r win-x64 --self-contained false -o $InstallDir
} else {
    Write-Warn "No source or pre-published binaries found in current path. Copy published binaries to $InstallDir before starting the service."
}

# ------------------------------------------------------------------------------
# Step 5: Provision Single-Use Bootstrap Enrollment Token
# ------------------------------------------------------------------------------
$BootstrapTokenPath = Join-Path $SecurityDir "bootstrap-enrollment.token"

if (-not [string]::IsNullOrWhiteSpace($TokenFile)) {
    if (-not (Test-Path $TokenFile)) {
        Write-Err "Specified -TokenFile '$TokenFile' does not exist."
        exit 1
    }
    $EnrollmentToken = (Get-Content -Path $TokenFile -Raw).Trim()
    Remove-Item -Path $TokenFile -Force
    Write-Ok "Read and securely deleted external token file '$TokenFile'."
}

if (-not [string]::IsNullOrWhiteSpace($EnrollmentToken)) {
    [System.IO.File]::WriteAllText($BootstrapTokenPath, $EnrollmentToken.Trim())
    $EnrollmentToken = $null
    Write-Ok "Provisioned single-use enrollment token at $BootstrapTokenPath (auto-scrubbed on first boot)."
}

# ------------------------------------------------------------------------------
# Step 6: Generate appsettings.Production.json
# ------------------------------------------------------------------------------
$allowOsBool = if ($AllowOsPartition.IsPresent) { $true } else { $false }
$outboxDbPath = Join-Path $OutboxDir "abodi-telemetry.db"

$prodConfig = @{
    SerilogConfig = @{
        WriteToFile = $true
        FileRetentionDays = 30
        WriteToSeq = $false
        SeqUrl = "http://localhost:5341"
        WriteToElasticsearch = $false
        ElasticsearchUrl = "http://localhost:9200"
    }
    Logging = @{
        LogLevel = @{
            Default = "Information"
            "Microsoft.Hosting.Lifetime" = "Information"
            "Microsoft.AspNetCore" = "Warning"
        }
    }
    AgentConfiguration = @{
        NodeCode = $NodeCode
        RokkaUrl = $RokkaUrl
        TelemetryIntervalSeconds = 10
        HeartbeatIntervalSeconds = 15
        ManifestCacheHours = 6
    }
    Cluster = @{
        TrustDomain = $TrustDomain
    }
    Security = @{
        TrustDomain = $TrustDomain
        IdentityStorageDirectory = $SecurityDir
        EnrollmentTokenFilePath = $BootstrapTokenPath
    }
    TelemetryOutbox = @{
        DatabasePath = $outboxDbPath
        MaxQueuedRecords = 50000
        MaxQueueSizeBytes = 52428800
        RetentionTtlHours = 72
        MaxRetries = 10
        MinFreeDiskSpaceBytes = 10737418240
    }
    Storage = @{
        Address = "https://0.0.0.0:57775"
        CoordinatorAddress = $RokkaUrl
        DataDirectory = $StorageDir
        AllowOsPartition = $allowOsBool
        EnableDirectIO = $true
    }
    Kestrel = @{
        Endpoints = @{
            "Rest-Https" = @{ Url = "https://0.0.0.0:57776"; Protocols = "Http1AndHttp2" }
            "Rest-Http"  = @{ Url = "http://127.0.0.1:7776"; Protocols = "Http1" }
            "gRPC-Https" = @{ Url = "https://0.0.0.0:57775"; Protocols = "Http1AndHttp2" }
            "gRPC-Http"  = @{ Url = "http://127.0.0.1:7775"; Protocols = "Http2" }
        }
    }
}

$configPath = Join-Path $InstallDir "appsettings.Production.json"
$prodConfig | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
Write-Ok "Generated production configuration at $configPath"

# ------------------------------------------------------------------------------
# Step 7: Configure Windows Defender Firewall
# ------------------------------------------------------------------------------
if (-not $SkipFirewall.IsPresent) {
    Write-Info "Configuring Windows Defender Firewall rules for Abodi mTLS ports (57775, 57776)..."
    $ruleNameGrpc = "Rokka Abodi gRPC mTLS (57775)"
    $ruleNameRest = "Rokka Abodi REST HTTPS (57776)"

    if (-not (Get-NetFirewallRule -DisplayName $ruleNameGrpc -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleNameGrpc -Direction Inbound -Protocol TCP -LocalPort 57775 -Action Allow -Profile Any | Out-Null
    }
    if (-not (Get-NetFirewallRule -DisplayName $ruleNameRest -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleNameRest -Direction Inbound -Protocol TCP -LocalPort 57776 -Action Allow -Profile Any | Out-Null
    }
    Write-Ok "Windows Defender Firewall rules configured."
}

# ------------------------------------------------------------------------------
# Step 8: Register & Start Windows Service
# ------------------------------------------------------------------------------
[Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Production", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ROKKA_IDENTITY_STORAGE_DIR", $SecurityDir, [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ROKKA_ENROLLMENT_TOKEN_FILE", $BootstrapTokenPath, [EnvironmentVariableTarget]::Machine)

$exePath = Join-Path $InstallDir "Abodi.exe"
$dllPath = Join-Path $InstallDir "Abodi.dll"
$dotnetExe = Join-Path $env:ProgramFiles "dotnet\dotnet.exe"

$binPath = if (Test-Path $exePath) { "`"$exePath`"" } else { "`"$dotnetExe`" `"$dllPath`"" }

if ($null -eq (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    Write-Info "Registering Windows Service '$ServiceName'..."
    New-Service -Name $ServiceName `
        -DisplayName "Rokka Abodi Zero-Trust Node Agent" `
        -BinaryPathName $binPath `
        -StartupType Automatic `
        -Description "Rokka Abodi Storage Node Agent, Hardware Telemetry & Zero-Trust mTLS Identity Daemon" | Out-Null
} else {
    & sc.exe config $ServiceName binPath= $binPath start= auto | Out-Null
}

# Configure automatic recovery on crash (restart after 5s)
& sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/5000/restart/5000 | Out-Null

if (Test-Path $dllPath) {
    Write-Info "Starting Windows Service '$ServiceName'..."
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 3
    $svcState = Get-Service -Name $ServiceName
    if ($svcState.Status -eq "Running") {
        Write-Ok "Service '$ServiceName' is active and running."
    } else {
        Write-Err "Service '$ServiceName' did not reach Running state (Current: $($svcState.Status)). Check Windows Event Viewer."
        exit 1
    }
} else {
    Write-Warn "Abodi binaries are not yet in $InstallDir. Copy binaries and run: Start-Service -Name '$ServiceName'"
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host " Rokka Abodi Node Agent Installation Complete (Windows Server)" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  Node Code:            $NodeCode"
Write-Host "  Rokka Coordinator:    $RokkaUrl"
Write-Host "  Install Directory:    $InstallDir"
Write-Host "  Zero-Trust Key Store: $SecurityDir (Protected NTFS ACL)"
Write-Host "  SQLite WAL Outbox:    $outboxDbPath"
Write-Host "  Storage Directory:    $StorageDir"
Write-Host "  Service Status:       Get-Service -Name '$ServiceName'"
Write-Host "==============================================================================" -ForegroundColor Green
