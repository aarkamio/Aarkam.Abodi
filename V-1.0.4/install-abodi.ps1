<#
.SYNOPSIS
    Aarkam Abodi Node Agent (v1.0.4-GA) — Automated Production Installation & Bootstrap Script for Windows Server.

.DESCRIPTION
    Automates the production deployment of the Rokka Abodi Sovereign Storage & Diagnostics Node Agent (v1.0.4-GA)
    on Windows Server 2022 / Windows Server 2025 (and Windows 10/11 Enterprise/Pro x64 for evaluation).
    Registers the Windows Service as 'Aarkam.Abodi'.

    Key Capabilities & Pre-Flight Checks:
    - Validates Ecosystem Version Compatibility Matrix (Abodi v1.0.4, Rokka Coordinator v1.0.2+, Kdouja SAT v1.0.2,
      Aarkam.Kdouja.SDK v1.0.1, Aarkam.Kdouja.Primitives v1.0.6, AM CLI v1.0.2+, Ahmodi Core v1.0.1).
    - Resolves NodeCode from CLI (-NodeCode), existing appsettings.Production.json / appsettings.json, or
      auto-generates a 15-character standard alphanumeric code formatted as 4-4-5
      (XXXX-XXXX-XXXXX, >=1 digit 0-9 in every part) and persists it to appsettings.json & appsettings.Production.json.
    - Computes and prints the deterministic Node Footprint (ARK-FP-XXXXXXXX-XXXXXXXX-XXXXXXXX & hw_<24-hex>)
      and hardware resource footprint (CPU Model, Physical Cores / Logical Threads, Physical RAM, Physical Disks / Volumes, Primary MAC).
    - Validates 64-bit (x64) architecture, Administrator privileges, Windows OS build, WMI/CIM Storage Management
      subsystem (MSFT_PhysicalDisk), Windows Time Service (w32time), RAM (>= 2 GB), and disk free space (>= 10 GB outbox).
    - Detects self-contained single-file native binaries (Abodi.exe) for 100% air-gapped operation without requiring
      an external .NET runtime download; verifies or installs .NET 10.0 ASP.NET Core Runtime only if running
      framework-dependent (Abodi.dll) or compiling from source (Abodi.csproj).
    - Supports Dual-Mode Kdouja SAT storage configuration:
        * Embedded (Default): In-process Kdouja PageStore & LSM-Tree engine via Aarkam.Kdouja.SDK.Embedded (v1.0.1).
        * Standalone: Sidecar/daemon connection to kdoujad (Aarkam.Kdouja.SAT v1.0.2) on 127.0.0.1:57771.
    - Registers and starts the 'Aarkam.Abodi' Windows Service with automatic crash recovery and probes
      /api/v1/health/ping and /healthz/kdouja.

.PARAMETER NodeCode
    Unique identifier for this storage node. If omitted, checks appsettings.json or auto-generates XXXX-XXXX-XXXXX (15 chars, 4-4-5).

.PARAMETER RokkaUrl
    Rokka Coordinator endpoint (defaults to "https://rokka-coordinator.aarkam:57774").

.PARAMETER TrustDomain
    Zero-Trust SPIFFE trust domain (default: "aarkam.cluster", matching Rokka Coordinator CA).

.PARAMETER EnrollmentToken
    Single-use bootstrap token (ET1.<hex>) issued by Rokka (via 'am node token create').

.PARAMETER TokenFile
    Path to a temporary file containing the single-use enrollment token (automatically scrubbed and deleted after reading).

.PARAMETER ApiKey
    Optional static or cluster-signed (AK1.*) node authentication key if not using single-use enrollment token.

.PARAMETER MasterKeyFile
    Optional path to a restricted file containing the 256-bit Kdouja cluster master key.

.PARAMETER SourcePath
    Path to pre-published Abodi binaries, a release .zip archive (abodi-v1.0.4-win-x64.zip), or repository root.

.PARAMETER InstallDir
    Target installation directory (default: "C:\Program Files\Aarkam\Abodi").

.PARAMETER StorageDir
    Dedicated non-OS storage directory (e.g., "D:\rokka_storage"). Defaults to first non-C: fixed drive if available.

.PARAMETER StorageMode
    Kdouja SAT execution mode: "Embedded" (default, in-process) or "Standalone" (connects to external kdoujad daemon).

.PARAMETER KdoujaEndpoint
    Standalone kdoujad gRPC endpoint when -StorageMode is "Standalone" (default: "http://127.0.0.1:57771").

.PARAMETER AllowOsPartition
    Switch to permit storage placement on the C: operating system partition (evaluation/development only).

.PARAMETER DisableDirectIO
    Switch to disable unbuffered hardware Direct I/O (FILE_FLAG_NO_BUFFERING) on virtual/emulated disks.

.PARAMETER StartService
    Switch to start the Aarkam.Abodi Windows Service after installation (enabled by default unless -SkipStartService is specified).

.PARAMETER SkipStartService
    Switch to register the Windows Service without starting it immediately.

.PARAMETER SkipFirewall
    Switch to skip Windows Defender Firewall rule creation.

.PARAMETER CheckOnly
    Switch to run pre-flight system requirements, version compatibility, NodeCode, and Node Footprint checks without modifying the system.

.EXAMPLE
    .\install-abodi.ps1 -RokkaUrl "https://rokka-coordinator.aarkam:57774" -EnrollmentToken "ET1.9f86d0..." -StorageDir "D:\rokka_storage"

.EXAMPLE
    .\install-abodi.ps1 -NodeCode "NODE-WIN-01" -RokkaUrl "https://rokka-coordinator.aarkam:57774" -EnrollmentToken "ET1.9f86d0..." -StorageDir "D:\rokka_storage" -StorageMode "Standalone" -KdoujaEndpoint "http://127.0.0.1:57771"
#>

[CmdletBinding()]
param(
    [string]$NodeCode = "",
    [string]$RokkaUrl = "https://rokka-coordinator.aarkam:57774",
    [string]$TrustDomain = "aarkam.cluster",
    [string]$EnrollmentToken = "",
    [string]$TokenFile = "",
    [string]$ApiKey = "",
    [string]$MasterKeyFile = "",
    [string]$SourcePath = "",
    [string]$InstallDir = "C:\Program Files\Aarkam\Abodi",
    [string]$StorageDir = "",
    [ValidateSet("Embedded", "Standalone")]
    [Alias("KdoujaMode")]
    [string]$StorageMode = "Embedded",
    [string]$KdoujaEndpoint = "http://127.0.0.1:57771",
    [switch]$AllowOsPartition,
    [switch]$DisableDirectIO,
    [switch]$StartService,
    [switch]$SkipStartService,
    [switch]$SkipFirewall,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

$ServiceName               = "Aarkam.Abodi"
$LegacyServiceName         = "Rokka.Abodi.Agent"
$AbodiReleaseVersion       = "1.0.4"
$RequiredRokkaMinVersion   = "1.0.2"
$RequiredKdoujaSatVersion  = "1.0.2"
$RequiredKdoujaSdkVersion  = "1.0.1"
$RequiredKdoujaPrimVersion = "1.0.6"
$RequiredAmCliMinVersion   = "1.0.2"
$RequiredDotNetMajor       = 10

function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Message) Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err   { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# ------------------------------------------------------------------------------
# Helper: Generate Random 15-Char NodeCode (XXXX-XXXX-XXXXX, >=1 digit per part)
# ------------------------------------------------------------------------------
function New-RandomAbodiNodePart {
    param([int]$Length)
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $buf = New-Object byte[] $Length
        while ($true) {
            $rng.GetBytes($buf)
            $sb = New-Object System.Text.StringBuilder $Length
            for ($i = 0; $i -lt $Length; $i++) {
                [void]$sb.Append($chars[$buf[$i] % $chars.Length])
            }
            $candidate = $sb.ToString()
            # Every part must contain one or more 0-9 digits (and at least one A-Z character)
            if ($candidate -match '[0-9]' -and $candidate -match '[A-Z]') {
                return $candidate
            }
        }
    } finally {
        if ($null -ne $rng) { $rng.Dispose() }
    }
}

function New-RandomAbodiNodeCode {
    $p1 = New-RandomAbodiNodePart -Length 4
    $p2 = New-RandomAbodiNodePart -Length 4
    $p3 = New-RandomAbodiNodePart -Length 5
    return "$p1-$p2-$p3" # Format: XXXX-XXXX-XXXXX (15 chars: 4-4-5, >=1 digit in every part)
}

function Test-ValidAbodiNodeCodeFormat {
    param([string]$Code)
    if ([string]::IsNullOrWhiteSpace($Code)) { return $false }
    # If it's an auto-generated 3-part code, require 4-4-5 (15 chars) with at least one 0-9 digit in every part
    if ($Code -match '^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4,5}$') {
        if ($Code.Length -ne 15) { return $false }
        $parts = $Code -split '-'
        foreach ($part in $parts) {
            if ($part -notmatch '[0-9]') { return $false }
        }
        return $true
    }
    return $true
}

# ------------------------------------------------------------------------------
# Helper: Read NodeCode from existing appsettings.json / appsettings.Production.json
# ------------------------------------------------------------------------------
function Get-ConfiguredNodeCodeFromAppSettings {
    param([string[]]$CandidateFiles)

    foreach ($file in $CandidateFiles) {
        if ([string]::IsNullOrWhiteSpace($file) -or -not (Test-Path $file -PathType Leaf)) {
            continue
        }
        try {
            $jsonRaw = Get-Content -Path $file -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($jsonRaw)) { continue }
            $jsonObj = $jsonRaw | ConvertFrom-Json -ErrorAction Stop

            $candidates = @(
                $jsonObj.AgentConfiguration.NodeCode,
                $jsonObj.RokkaClientConfiguration.NodeCode,
                $jsonObj.Abodi.NodeCode,
                $jsonObj.Node.NodeCode
            )
            foreach ($val in $candidates) {
                if (-not [string]::IsNullOrWhiteSpace($val)) {
                    $trimmed = ([string]$val).Trim()
                    # Treat default template placeholder 'N-1', 'YOUR_NODE_CODE', legacy $env:COMPUTERNAME, or old 14-char codes as unconfigured
                    if ($trimmed -ine "N-1" -and
                        $trimmed -ine "YOUR_NODE_CODE" -and
                        $trimmed -ine "NODE-placeholder" -and
                        $trimmed -ine $env:COMPUTERNAME -and
                        (Test-ValidAbodiNodeCodeFormat -Code $trimmed)) {
                        return @{
                            NodeCode = $trimmed
                            SourceFile = $file
                        }
                    }
                }
            }
        } catch {
            # Ignore malformed or inaccessible JSON candidate
        }
    }
    return $null
}

# ------------------------------------------------------------------------------
# Helper: Query Real Physical Hardware Specifications (Win32 P/Invoke + CIM + Registry)
# ------------------------------------------------------------------------------
function Get-AbodiHardwareSpecs {
    $logicalThreads = [System.Environment]::ProcessorCount
    $physicalCores  = 0
    $socketCount    = 1
    $cpuModel       = ""
    $totalRamMB     = 0
    $physDiskCount  = 0
    $wmiStorageOk   = $false

    # 1. Load Win32 Native Helper (GlobalMemoryStatusEx + GetLogicalProcessorInformation)
    # Works in both Windows PowerShell 5.1 and PowerShell 7+ even when WMI/CIM is restricted
    try {
        if (-not ("Aarkam.Abodi.Win32HwNative" -as [type])) {
            Add-Type -Namespace "Aarkam.Abodi" -Name "Win32HwNative" -MemberDefinition @"
[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public struct MEMORYSTATUSEX {
    public uint dwLength;
    public uint dwMemoryLoad;
    public ulong ullTotalPhys;
    public ulong ullAvailPhys;
    public ulong ullTotalPageFile;
    public ulong ullAvailPageFile;
    public ulong ullTotalVirtual;
    public ulong ullAvailVirtual;
    public ulong ullAvailExtendedVirtual;
}

[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
public struct SYSTEM_LOGICAL_PROCESSOR_INFORMATION {
    public System.UIntPtr ProcessorMask;
    public int Relationship;
    public ulong Reserved1;
    public ulong Reserved2;
}

[System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetLogicalProcessorInformation(System.IntPtr Buffer, ref uint ReturnLength);

public static ulong GetTotalPhysicalMemoryBytes() {
    MEMORYSTATUSEX mem = new MEMORYSTATUSEX();
    mem.dwLength = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(MEMORYSTATUSEX));
    if (GlobalMemoryStatusEx(ref mem)) {
        return mem.ullTotalPhys;
    }
    return 0;
}

public static int GetPhysicalCoreCount() {
    uint returnLength = 0;
    GetLogicalProcessorInformation(System.IntPtr.Zero, ref returnLength);
    if (returnLength == 0) return 0;
    System.IntPtr ptr = System.Runtime.InteropServices.Marshal.AllocHGlobal((int)returnLength);
    try {
        if (GetLogicalProcessorInformation(ptr, ref returnLength)) {
            int structSize = System.Runtime.InteropServices.Marshal.SizeOf(typeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION));
            int count = (int)returnLength / structSize;
            int cores = 0;
            for (int i = 0; i < count; i++) {
                System.IntPtr itemPtr = new System.IntPtr(ptr.ToInt64() + i * structSize);
                SYSTEM_LOGICAL_PROCESSOR_INFORMATION info = (SYSTEM_LOGICAL_PROCESSOR_INFORMATION)System.Runtime.InteropServices.Marshal.PtrToStructure(itemPtr, typeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION));
                if (info.Relationship == 0) { // RelationProcessorCore
                    cores++;
                }
            }
            return cores;
        }
    } finally {
        System.Runtime.InteropServices.Marshal.FreeHGlobal(ptr);
    }
    return 0;
}
"@ -ErrorAction SilentlyContinue
        }
    } catch { }

    # 2. CPU Model Name & Physical Cores
    try {
        $regCpuName = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0", "ProcessorNameString", $null)
        if (-not [string]::IsNullOrWhiteSpace($regCpuName)) {
            $cpuModel = ([string]$regCpuName).Trim() -replace '\s+', ' '
        }
    } catch { }

    try {
        $cimProcs = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        if ($cimProcs.Count -gt 0) {
            $socketCount = $cimProcs.Count
            $sumCores = 0
            $sumLogical = 0
            foreach ($p in $cimProcs) {
                $sumCores += [int]$p.NumberOfCores
                $sumLogical += [int]$p.NumberOfLogicalProcessors
                if ([string]::IsNullOrWhiteSpace($cpuModel) -and -not [string]::IsNullOrWhiteSpace($p.Name)) {
                    $cpuModel = ([string]$p.Name).Trim() -replace '\s+', ' '
                }
            }
            if ($sumCores -gt 0) { $physicalCores = $sumCores }
            if ($sumLogical -gt 0) { $logicalThreads = $sumLogical }
        }
    } catch { }

    if ($physicalCores -le 0) {
        try {
            $physicalCores = [Aarkam.Abodi.Win32HwNative]::GetPhysicalCoreCount()
        } catch { }
    }
    if ($physicalCores -le 0) {
        $physicalCores = $logicalThreads
    }
    if ([string]::IsNullOrWhiteSpace($cpuModel)) {
        $cpuModel = "x64 Processor"
    }

    # 3. Physical RAM (MB & Installed GB)
    try {
        $physBytes = [Aarkam.Abodi.Win32HwNative]::GetTotalPhysicalMemoryBytes()
        if ($physBytes -gt 0) {
            $totalRamMB = [int][math]::Round($physBytes / 1MB)
        }
    } catch { }

    # 4. OS Caption & Build Number
    $osCaption = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    $buildNum  = [System.Environment]::OSVersion.Version.Build
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($osInfo.Caption)) {
            $osCaption = ([string]$osInfo.Caption).Trim()
        }
        if ($osInfo.BuildNumber) {
            $buildNum = [int]$osInfo.BuildNumber
        }
        if ($totalRamMB -le 0 -and $osInfo.TotalVisibleMemorySize -gt 0) {
            $totalRamMB = [int][math]::Round($osInfo.TotalVisibleMemorySize / 1024)
        }
    } catch {
        try {
            $regProdName = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName", $null)
            $regBuild    = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CurrentBuildNumber", $null)
            if (-not [string]::IsNullOrWhiteSpace($regBuild)) {
                $buildNum = [int]$regBuild
            }
            if (-not [string]::IsNullOrWhiteSpace($regProdName)) {
                $osCaption = ([string]$regProdName).Trim()
                if ($buildNum -ge 22000 -and $osCaption -match "Windows 10") {
                    $osCaption = $osCaption -replace "Windows 10", "Windows 11"
                }
            }
        } catch { }
    }

    if ($totalRamMB -le 0) {
        try {
            $gcMemBytes = [System.GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes
            if ($gcMemBytes -gt 0) {
                $totalRamMB = [int][math]::Round($gcMemBytes / 1MB)
            }
        } catch { }
    }
    if ($totalRamMB -le 0) {
        $totalRamMB = 8192
    }
    $totalRamGB = [int][math]::Round($totalRamMB / 1024.0)

    # 5. Physical Disks vs. Fixed Logical Volumes
    $fixedVolumes = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and $_.DriveType -eq [System.IO.DriveType]::Fixed })
    $fixedVolumeCount = $fixedVolumes.Count

    try {
        $physDisks = @(Get-CimInstance -Namespace "root\Microsoft\Windows\Storage" -ClassName "MSFT_PhysicalDisk" -ErrorAction Stop)
        if ($physDisks.Count -gt 0) {
            $physDiskCount = $physDisks.Count
            $wmiStorageOk = $true
        }
    } catch {
        try {
            $wmiDisks = @(Get-CimInstance -ClassName "Win32_DiskDrive" -ErrorAction Stop)
            if ($wmiDisks.Count -gt 0) {
                $physDiskCount = $wmiDisks.Count
                $wmiStorageOk = $true
            }
        } catch { }
    }

    if ($physDiskCount -le 0) {
        try {
            $regDiskCount = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\disk\Enum", "Count", 0)
            if ($null -ne $regDiskCount -and [int]$regDiskCount -gt 0) {
                $physDiskCount = [int]$regDiskCount
            }
        } catch { }
    }
    if ($physDiskCount -le 0) {
        $physDiskCount = if ($fixedVolumeCount -gt 0) { $fixedVolumeCount } else { 1 }
    }

    return @{
        OsCaption        = $osCaption
        BuildNumber      = $buildNum
        CpuModel         = $cpuModel
        SocketCount      = $socketCount
        PhysicalCores    = $physicalCores
        LogicalThreads   = $logicalThreads
        TotalRamMB       = $totalRamMB
        TotalRamGB       = $totalRamGB
        PhysicalDisks    = $physDiskCount
        FixedVolumes     = $fixedVolumeCount
        WmiStorageActive = $wmiStorageOk
    }
}

# ------------------------------------------------------------------------------
# Helper: Compute Deterministic Node Footprint (ARK-FP-* & hw_*)
# ------------------------------------------------------------------------------
function Get-AbodiNodeFootprint {
    param(
        [hashtable]$HwSpecs
    )

    $machineName = [System.Environment]::MachineName
    $procCount   = $HwSpecs.LogicalThreads
    $physCores   = $HwSpecs.PhysicalCores
    $cpuModel    = $HwSpecs.CpuModel
    $totalRamMB  = $HwSpecs.TotalRamMB
    $totalRamGB  = $HwSpecs.TotalRamGB
    $physDisks   = $HwSpecs.PhysicalDisks
    $fixedVols   = $HwSpecs.FixedVolumes
    $osArch      = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToUpperInvariant()
    $osDesc      = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    if ([string]::IsNullOrWhiteSpace($osDesc)) { $osDesc = $HwSpecs.OsCaption }

    # 1. Abodi Enrollment Hardware Fingerprint (matches NodeEnrollmentBootstrapWorker.ComputeLocalHardwareFingerprint)
    $rawEnrollIdentity = "$machineName|$osDesc|$osArch|$procCount"
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $enrollHash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($rawEnrollIdentity))
    } finally {
        $sha256.Dispose()
    }
    $hwHex = ([System.BitConverter]::ToString($enrollHash, 0, 12) -replace '-', '').ToLowerInvariant()
    $abodiHwFp = "hw_$hwHex"

    # 2. Primary Physical MAC Address (matches ClusterHardwareProfiler.GetPrimaryMacAddress)
    $primaryMac = "00155D000001"
    try {
        $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()
        foreach ($nic in $nics) {
            if ($nic.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $nic.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and
                $nic.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel) {
                $addrBytes = $nic.GetPhysicalAddress().GetAddressBytes()
                if ($null -ne $addrBytes -and $addrBytes.Length -gt 0) {
                    $primaryMac = ([System.BitConverter]::ToString($addrBytes) -replace '-', '').ToUpperInvariant()
                    break
                }
            }
        }
    } catch { }

    # 3. Aarkam Sovereign Hardware Footprint (matches ClusterHardwareProfiler.GetClusterFingerprint)
    $officialRootPubKey = [byte[]]@(
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0F, 0x00, 0x30, 0x82, 0x02, 0x0A, 0x02, 0x82, 0x02, 0x01,
        0x00, 0xC2, 0x8D, 0x69, 0x15, 0x05, 0x4C, 0xC6, 0x7E, 0x58, 0x87, 0xA6, 0xE1, 0x03, 0x5A, 0x37,
        0x6D, 0xB5, 0x7C, 0xE2, 0x90, 0xE7, 0xA4, 0x54, 0x55, 0xD4, 0xE8, 0x23, 0xD2, 0xA3, 0x43, 0x96,
        0xDC, 0x5F, 0x15, 0x50, 0x71, 0xC9, 0x0E, 0x95, 0xCB, 0xE4, 0x29, 0xF7, 0x17, 0x7B, 0x7B, 0x35,
        0xA3, 0xF0, 0x33, 0xE4, 0x50, 0x9F, 0x65, 0xEE, 0x30, 0xC4, 0xA4, 0x0F, 0x17, 0x0D, 0xBC, 0x21,
        0x36, 0x25, 0x7B, 0x39, 0x39, 0x9C, 0xDC, 0xE4, 0xA7, 0xFA, 0xEA, 0x53, 0xCC, 0x49, 0xE5, 0x30,
        0x71, 0x6B, 0x54, 0x15, 0x02, 0x73, 0xE2, 0xCB, 0x76, 0xE8, 0x55, 0xC8, 0x36, 0x16, 0x12, 0x5A,
        0xB1, 0x8D, 0x65, 0x51, 0x15, 0x62, 0x51, 0x27, 0x12, 0xC9, 0x31, 0xAC, 0xF6, 0x98, 0x11, 0x69,
        0x3B, 0xCE, 0xB7, 0xC2, 0x42, 0x1D, 0xB7, 0x72, 0x44, 0x3E, 0xC6, 0xC0, 0x0B, 0xE4, 0x9D, 0xD1,
        0x17, 0x58, 0x83, 0x58, 0xA5, 0xAD, 0xA9, 0x09, 0x23, 0xA2, 0x07, 0xD9, 0xDB, 0xCE, 0x92, 0x0C,
        0x41, 0x26, 0x45, 0x12, 0x7C, 0x72, 0x83, 0xAA, 0x69, 0x57, 0xE2, 0x95, 0xE1, 0xFB, 0xE7, 0xF2,
        0xD8, 0x64, 0x9B, 0x0D, 0x15, 0x1B, 0x2E, 0xFF, 0x5B, 0x25, 0xAF, 0xF3, 0xEB, 0x5C, 0xED, 0x87,
        0x26, 0xE6, 0x5A, 0x2B, 0x16, 0x0F, 0xAE, 0x20, 0xB5, 0x67, 0x87, 0xC4, 0x2F, 0x30, 0x70, 0x8A,
        0x72, 0x5B, 0xC9, 0x65, 0xBE, 0xA6, 0x54, 0x07, 0x8D, 0xD7, 0xE5, 0x3B, 0xC2, 0x45, 0xA7, 0xEE,
        0xF6, 0x17, 0x5B, 0xD6, 0xB6, 0xD2, 0x5A, 0xCF, 0x38, 0xB2, 0x4D, 0x48, 0x15, 0x62, 0xCF, 0x25,
        0xB9, 0xEC, 0x12, 0xF2, 0x1E, 0x39, 0xE8, 0xC5, 0x58, 0xC1, 0x58, 0x7D, 0x9E, 0x18, 0x44, 0x49,
        0x74, 0xC4, 0xC3, 0x4C, 0x77, 0x2A, 0x14, 0x22, 0x33, 0xB9, 0xB7, 0x0F, 0xF2, 0x35, 0x20, 0xB1,
        0x97, 0xA4, 0x8A, 0x3E, 0x05, 0x2C, 0x1D, 0xE3, 0x29, 0xBB, 0x39, 0xDE, 0xE2, 0xB7, 0x80, 0x59,
        0x32, 0x82, 0xC1, 0x1A, 0xF3, 0xB8, 0xD8, 0xD8, 0xB5, 0xBB, 0x2A, 0xFB, 0x01, 0x9F, 0x60, 0x5A,
        0x90, 0x7E, 0x2B, 0x23, 0x6E, 0xB4, 0xD2, 0x8D, 0x9B, 0x79, 0x5C, 0x0D, 0xB1, 0x27, 0x19, 0x66,
        0xD9, 0xBA, 0xD4, 0x53, 0x73, 0x17, 0x9C, 0xE2, 0x23, 0xC6, 0xE7, 0xC3, 0x9C, 0xB0, 0xD5, 0x8D,
        0x91, 0x20, 0x06, 0xCA, 0xDC, 0x57, 0x8C, 0xCF, 0x06, 0x75, 0xE8, 0xFB, 0x47, 0x25, 0xEC, 0x2E,
        0x74, 0x20, 0x42, 0x5F, 0x14, 0xE1, 0xA3, 0x1B, 0x94, 0x72, 0xCA, 0x48, 0x75, 0x57, 0x9A, 0x04,
        0xC0, 0xB0, 0x94, 0x23, 0x80, 0x93, 0x7C, 0xB0, 0xA2, 0x0F, 0xDB, 0xE1, 0x8C, 0x66, 0xFB, 0x0F,
        0x30, 0x08, 0x3B, 0x09, 0x25, 0xBE, 0xD4, 0xAC, 0x3F, 0xFC, 0x9F, 0xD9, 0xA4, 0x7B, 0xA9, 0x59,
        0x40, 0x58, 0x7C, 0x3C, 0xEC, 0x88, 0x02, 0xD7, 0x8B, 0x02, 0xEB, 0xF1, 0xDA, 0xE7, 0x36, 0x08,
        0xB9, 0x71, 0xA1, 0x65, 0xF0, 0xDF, 0xB1, 0x7A, 0xD5, 0x90, 0x72, 0xD8, 0x1D, 0xE0, 0x7E, 0xF2,
        0x42, 0x87, 0x0E, 0x23, 0xC5, 0x10, 0x60, 0x24, 0x3E, 0x6B, 0xE5, 0x9D, 0x8C, 0x78, 0x3C, 0x65,
        0xAA, 0x11, 0xE2, 0xF7, 0x51, 0xE5, 0x14, 0xA8, 0x00, 0xCF, 0x04, 0xE0, 0x28, 0x4C, 0xA6, 0xD6,
        0x60, 0x2E, 0xC8, 0x4D, 0x16, 0xA1, 0x34, 0xCB, 0x32, 0x91, 0xEB, 0x8C, 0xA4, 0xA4, 0x9A, 0xE8,
        0x52, 0xF7, 0x3F, 0x8D, 0xDE, 0x79, 0x85, 0x08, 0xB0, 0x81, 0x85, 0xF6, 0x45, 0xD3, 0x8D, 0x1F,
        0xD0, 0x18, 0x11, 0xF3, 0x5C, 0x23, 0xCF, 0x16, 0xA6, 0xAD, 0x02, 0x81, 0xD3, 0xE4, 0xC3, 0x38,
        0x3F, 0x24, 0x6B, 0x06, 0x84, 0x9C, 0x74, 0x50, 0xA7, 0xAF, 0x98, 0x75, 0x63, 0x30, 0x9F, 0x81,
        0x09, 0x02, 0x03, 0x01, 0x00, 0x01
    )

    $machineId = if (-not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) { $env:COMPUTERNAME } else { $machineName }
    $profilePayload = "$($machineName.Trim().ToUpperInvariant())|$procCount|$osArch|$machineId|$primaryMac"
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 (,$officialRootPubKey)
    try {
        $hmacBytes = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($profilePayload))
    } finally {
        $hmac.Dispose()
    }
    $arkHex = ([System.BitConverter]::ToString($hmacBytes) -replace '-', '').ToUpperInvariant()
    $arkFp = "ARK-FP-$($arkHex.Substring(0,8))-$($arkHex.Substring(8,8))-$($arkHex.Substring(16,8))"

    $cpuTopology = if ($physCores -ne $procCount) {
        "$physCores Cores / $procCount Logical Threads, $osArch"
    } else {
        "$physCores Cores, $osArch"
    }

    $diskTopology = if ($fixedVols -gt 0 -and $fixedVols -ne $physDisks) {
        "$physDisks Physical Disk(s) ($fixedVols Fixed Volumes)"
    } else {
        "$physDisks Physical Disk(s)"
    }

    return @{
        ArkFingerprint   = $arkFp
        AbodiFingerprint = $abodiHwFp
        CombinedId       = "$arkFp ($abodiHwFp)"
        HardwareSummary  = "$cpuModel ($cpuTopology) | $totalRamMB MB ($totalRamGB GB) RAM | $diskTopology | MAC: $primaryMac"
    }
}

Write-Host "==============================================================================" -ForegroundColor Blue
Write-Host " Aarkam Abodi Sovereign Storage & Diagnostics Node Daemon — Windows Installer " -ForegroundColor Cyan
Write-Host " Release Version: v$AbodiReleaseVersion-GA (V-$AbodiReleaseVersion) | Service: $ServiceName (.NET $RequiredDotNetMajor.0 x64) " -ForegroundColor Blue
Write-Host "==============================================================================" -ForegroundColor Blue

# ------------------------------------------------------------------------------
# Step 0: Locate Release Payload & Resolve NodeCode (CLI -> appsettings.json -> Random 15-Char)
# ------------------------------------------------------------------------------
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = "C:\Program Files\Aarkam\Abodi"
}

$tempZipExtract = ""
$resolvedSourceDir = ""
$resolvedCsproj = ""
$isSelfContainedBinary = $false

$candidateSources = @()
if (-not [string]::IsNullOrWhiteSpace($SourcePath)) {
    $candidateSources += $SourcePath
}
$candidateSources += @(
    (Get-Location).Path,
    $ScriptRoot,
    (Join-Path $ScriptRoot "win"),
    (Join-Path $ScriptRoot "V-$AbodiReleaseVersion\win"),
    (Join-Path $ScriptRoot "V-$AbodiReleaseVersion\abodi-v$AbodiReleaseVersion-win-x64.zip"),
    (Join-Path $ScriptRoot "abodi-v$AbodiReleaseVersion-win-x64.zip"),
    (Join-Path $ScriptRoot "..\dist\bundles\abodi-v$AbodiReleaseVersion-win-x64.zip"),
    (Join-Path $ScriptRoot "..")
)

foreach ($cand in $candidateSources) {
    if ([string]::IsNullOrWhiteSpace($cand) -or -not (Test-Path $cand)) { continue }

    if ((Test-Path $cand -PathType Leaf) -and $cand.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
        if (-not $CheckOnly.IsPresent) {
            Write-Info "Extracting release archive '$cand'..."
            $tempZipExtract = Join-Path ([System.IO.Path]::GetTempPath()) ("abodi_inst_" + [Guid]::NewGuid().ToString("N"))
            Expand-Archive -Path $cand -DestinationPath $tempZipExtract -Force
            $cand = $tempZipExtract
        } else {
            Write-Ok "Found release archive: $cand"
            $isSelfContainedBinary = $true
            break
        }
    }

    if (Test-Path $cand -PathType Container) {
        $exeCandidate = Join-Path $cand "Abodi.exe"
        $dllCandidate = Join-Path $cand "Abodi.dll"
        $csprojCandidate = Join-Path $cand "src\Abodi\Abodi.csproj"

        if (Test-Path $exeCandidate) {
            $resolvedSourceDir = (Resolve-Path $cand).Path
            if (-not (Test-Path $dllCandidate)) {
                $isSelfContainedBinary = $true
            }
            $fileVer = (Get-Item $exeCandidate).VersionInfo.ProductVersion
            Write-Ok "Located Abodi Windows executable: $exeCandidate (Version: $fileVer, SelfContainedSingleFile: $isSelfContainedBinary)"
            break
        } elseif (Test-Path $dllCandidate) {
            $resolvedSourceDir = (Resolve-Path $cand).Path
            $isSelfContainedBinary = $false
            Write-Ok "Located framework-dependent Abodi assembly: $dllCandidate"
            break
        } elseif (Test-Path $csprojCandidate) {
            $resolvedCsproj = (Resolve-Path $csprojCandidate).Path
            Write-Ok "Located Abodi source project: $resolvedCsproj"
            break
        }
    }
}

# Resolve NodeCode:
# 1. Explicit -NodeCode parameter
# 2. Existing appsettings.Production.json / appsettings.json
# 3. Auto-generate random 15-char XXXX-XXXX-XXXXX (4-4-5, >=1 digit 0-9 in every part)
$NodeCodeSource = ""
if (-not [string]::IsNullOrWhiteSpace($NodeCode)) {
    $NodeCode = $NodeCode.Trim()
    $NodeCodeSource = "CLI Parameter (-NodeCode)"
} else {
    $appSettingsCandidates = @(
        (Join-Path (Get-Location).Path "appsettings.json"),
        (Join-Path $ScriptRoot "appsettings.json"),
        (Join-Path $InstallDir "appsettings.json"),
        (Join-Path $InstallDir "appsettings.Production.json")
    )
    if (-not [string]::IsNullOrWhiteSpace($resolvedSourceDir)) {
        $appSettingsCandidates += (Join-Path $resolvedSourceDir "appsettings.json")
        $appSettingsCandidates += (Join-Path $resolvedSourceDir "appsettings.Production.json")
    }
    $appSettingsCandidates += @(
        (Join-Path (Get-Location).Path "appsettings.Production.json"),
        (Join-Path $ScriptRoot "appsettings.Production.json")
    )

    $foundCfg = Get-ConfiguredNodeCodeFromAppSettings -CandidateFiles $appSettingsCandidates
    if ($null -ne $foundCfg) {
        $NodeCode = $foundCfg.NodeCode
        $NodeCodeSource = "Loaded from $($foundCfg.SourceFile)"
        Write-Ok "Resolved existing NodeCode '$NodeCode' from '$($foundCfg.SourceFile)'."
    } else {
        $NodeCode = New-RandomAbodiNodeCode
        $NodeCodeSource = "Auto-Generated (XXXX-XXXX-XXXXX, 15 chars)"
        Write-Info "Generated random NodeCode: $NodeCode (15 chars [4-4-5], each part with >=1 digit)"
    }
}

Write-Info "Validating Aarkam V2 Ecosystem Version Compatibility Matrix:"
Write-Host "  • Aarkam Abodi Node Daemon   : v$AbodiReleaseVersion-GA (V-$AbodiReleaseVersion) | Service: $ServiceName" -ForegroundColor Gray
Write-Host "  • Aarkam Rokka Coordinator   : >= v$RequiredRokkaMinVersion (Rokka.Contracts $RequiredRokkaMinVersion, mTLS :57774)" -ForegroundColor Gray
Write-Host "  • Aarkam Kdouja SAT Daemon   : v$RequiredKdoujaSatVersion (kdoujad :57771) | Mode: $StorageMode" -ForegroundColor Gray
Write-Host "  • Aarkam.Kdouja.SDK Suite    : v$RequiredKdoujaSdkVersion (Primitives v$RequiredKdoujaPrimVersion, Engine v2.0.0)" -ForegroundColor Gray
Write-Host "  • Aarkam AM Fleet CLI        : >= v$RequiredAmCliMinVersion" -ForegroundColor Gray
Write-Host "  • Zero-Trust SPIFFE Domain   : spiffe://$TrustDomain/node/$NodeCode" -ForegroundColor Gray

# Normalize and Validate Rokka Coordinator URL
$RokkaUrl = $RokkaUrl.Trim()
if (-not $RokkaUrl.StartsWith("http://", [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $RokkaUrl.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
    $RokkaUrl = "https://$RokkaUrl"
}

try {
    $parsedUri = [System.Uri]$RokkaUrl
    $effectivePort = if ($parsedUri.Port -gt 0) { $parsedUri.Port } elseif ($parsedUri.Scheme -eq "https") { 443 } else { 80 }
    Write-Ok "Target Rokka Coordinator URL validated: $RokkaUrl (Host: $($parsedUri.Host), Port: $effectivePort)"
} catch {
    Write-Err "Invalid Rokka Coordinator URL: '$RokkaUrl'. Expected a valid URI (e.g. 'https://rokka-coordinator.aarkam:57774' or 'https://10.20.0.10:57774')."
    exit 1
}

$StorageMode = if ($StorageMode -ieq "Standalone") { "Standalone" } else { "Embedded" }

# ------------------------------------------------------------------------------
# Step 1: Verify Architecture, Administrator Privileges, OS & Node Footprint
# ------------------------------------------------------------------------------
if ([IntPtr]::Size -ne 8 -or ($env:PROCESSOR_ARCHITECTURE -ne "AMD64" -and $env:PROCESSOR_ARCHITEW6432 -ne "AMD64")) {
    Write-Err "Unsupported CPU architecture. Abodi v$AbodiReleaseVersion requires 64-bit (x64 / AMD64) Windows."
    exit 1
}
Write-Ok "CPU architecture check passed (x64 / AMD64)."

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Err "PowerShell 5.1 or newer is required (Detected: $($PSVersionTable.PSVersion))."
    exit 1
}
Write-Ok "PowerShell runtime check passed (v$($PSVersionTable.PSVersion))."

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($CheckOnly.IsPresent) {
        Write-Warn "Running in -CheckOnly mode without Administrator elevation. Service registration requires Run as Administrator."
    } else {
        Write-Err "This installer must be run from an elevated PowerShell prompt (Run as Administrator)."
        exit 1
    }
} else {
    Write-Ok "Administrator privilege check passed."
}

$hwSpecs    = Get-AbodiHardwareSpecs
$osCaption  = $hwSpecs.OsCaption
$buildNum   = $hwSpecs.BuildNumber
$totalRamMB = $hwSpecs.TotalRamMB
$totalRamGB = $hwSpecs.TotalRamGB
Write-Info "Detected OS: $osCaption (Build $buildNum) | CPU: $($hwSpecs.CpuModel) ($($hwSpecs.PhysicalCores) Cores / $($hwSpecs.LogicalThreads) Threads) | RAM: $totalRamMB MB ($totalRamGB GB)"

if ($buildNum -lt 19044) {
    Write-Warn "Windows Build $buildNum is older than recommended baseline (Windows Server 2022 Build 20348+ / Windows 10 21H2 Build 19044+)."
} else {
    Write-Ok "Windows OS build compatibility verified (Build $buildNum)."
}

if ($totalRamMB -lt 1800) {
    Write-Warn "Host has $totalRamMB MB RAM. Minimum required is 2,048 MB (16,384 MB+ recommended for production storage nodes)."
} else {
    Write-Ok "Memory check passed ($totalRamMB MB / $totalRamGB GB physical RAM installed)."
}

if ($hwSpecs.WmiStorageActive) {
    Write-Ok "Verified Windows Storage Management WMI provider ($($hwSpecs.PhysicalDisks) physical disk(s), $($hwSpecs.FixedVolumes) fixed volume(s) visible)."
} else {
    if ($CheckOnly.IsPresent -and -not $isAdmin) {
        Write-Ok "Detected $($hwSpecs.PhysicalDisks) physical disk(s) and $($hwSpecs.FixedVolumes) fixed logical volume(s) (Registry + DriveInfo inventory)."
    } else {
        Write-Warn "Windows Storage WMI namespace unavailable; using Registry + DriveInfo inventory ($($hwSpecs.PhysicalDisks) physical disk(s), $($hwSpecs.FixedVolumes) fixed volume(s))."
    }
}

$nodeFootprint = Get-AbodiNodeFootprint -HwSpecs $hwSpecs
Write-Ok "Computed Node Footprint: $($nodeFootprint.CombinedId)"
Write-Info "Hardware Resource Footprint: $($nodeFootprint.HardwareSummary)"

# Verify Windows Time Service (w32time) for mTLS clock skew compliance
$w32time = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
if ($null -ne $w32time) {
    if ($w32time.Status -ne "Running") {
        if (-not $CheckOnly.IsPresent -and $isAdmin) {
            Write-Info "Starting Windows Time Service (w32time) for mTLS certificate clock synchronization..."
            Set-Service -Name "w32time" -StartupType Automatic
            Start-Service -Name "w32time"
            Write-Ok "Windows Time Service (w32time) started."
        } else {
            Write-Warn "Windows Time Service (w32time) is not running. mTLS requires synchronized system clocks."
        }
    } else {
        Write-Ok "Windows Time Service (w32time) is active and running."
    }
}

# ------------------------------------------------------------------------------
# Step 2: Verify or Install .NET 10.0 ASP.NET Core Runtime (Only if Needed)
# ------------------------------------------------------------------------------
function Ensure-DotNet10Runtime {
    param([bool]$SelfContainedAvailable)

    $dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
    if ($null -ne $dotnetCmd) {
        $runtimes = & dotnet --list-runtimes 2>$null
        if ($runtimes -match "Microsoft\.AspNetCore\.App 10\.") {
            Write-Ok ".NET 10.0 ASP.NET Core Runtime detected on host."
            return
        }
    }

    if ($SelfContainedAvailable) {
        Write-Ok "Self-contained single-file Abodi.exe detected; external .NET 10.0 runtime installation is not required (air-gap ready)."
        return
    }

    if ($CheckOnly.IsPresent) {
        Write-Warn ".NET 10.0 ASP.NET Core Runtime is not installed and no self-contained Abodi.exe was found."
        return
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

Ensure-DotNet10Runtime -SelfContainedAvailable $isSelfContainedBinary

if ($StorageMode -eq "Standalone") {
    Write-Info "Verifying Standalone Kdouja SAT (v$RequiredKdoujaSatVersion) prerequisite at '$KdoujaEndpoint'..."
    $kdoujaCmd = Get-Command "kdoujad.exe" -ErrorAction SilentlyContinue
    if ($null -ne $kdoujaCmd) {
        Write-Ok "Detected local kdoujad binary: $($kdoujaCmd.Source)"
    } elseif (Test-Path "$env:ProgramFiles\Aarkam\Kdouja\kdoujad.exe") {
        Write-Ok "Detected installed Aarkam Kdouja SAT daemon at '$env:ProgramFiles\Aarkam\Kdouja\kdoujad.exe'."
    } else {
        Write-Warn "kdoujad.exe not found in PATH or '$env:ProgramFiles\Aarkam\Kdouja'. Ensure Aarkam Kdouja SAT v$RequiredKdoujaSatVersion is running at $KdoujaEndpoint."
    }
}

# ------------------------------------------------------------------------------
# Step 3: Resolve Storage Paths, Verify Disk Free Space & Enforce NTFS ACLs
# ------------------------------------------------------------------------------
$ProgramData = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)
$RokkaData   = Join-Path $ProgramData "Rokka"
$SecurityDir = Join-Path $RokkaData "Security"
$OutboxDir   = Join-Path $RokkaData "Outbox"
$LogDir      = Join-Path $RokkaData "Logs\Abodi"

if ([string]::IsNullOrWhiteSpace($StorageDir)) {
    $nonOsDrive = [System.IO.DriveInfo]::GetDrives() |
        Where-Object { $_.IsReady -and $_.DriveType -eq [System.IO.DriveType]::Fixed -and -not $_.Name.StartsWith("C:", [System.StringComparison]::OrdinalIgnoreCase) } |
        Select-Object -First 1

    if ($null -ne $nonOsDrive) {
        $driveLetter = $nonOsDrive.Name.Substring(0, 1)
        $StorageDir = "${driveLetter}:\rokka_storage"
        Write-Info "Auto-selected dedicated non-OS storage volume: $StorageDir"
    } else {
        $StorageDir = Join-Path $RokkaData "Storage"
        if (-not $AllowOsPartition.IsPresent) {
            Write-Warn "No non-C: drive detected. Pass -AllowOsPartition for evaluation/PoC on single-disk systems, or attach a dedicated data disk."
        }
    }
}

$systemRootDrive = ([System.IO.Path]::GetPathRoot($env:SystemRoot)).TrimEnd('\', '/')
$storageRootDrive = ([System.IO.Path]::GetPathRoot($StorageDir)).TrimEnd('\', '/')
if ($systemRootDrive -ieq $storageRootDrive -and -not $AllowOsPartition.IsPresent) {
    Write-Warn "StorageDir '$StorageDir' is on OS partition ($systemRootDrive). Abodi requires a non-OS drive in production unless -AllowOsPartition is set."
}

$outboxRoot = [System.IO.Path]::GetPathRoot($OutboxDir)
try {
    $outboxDriveInfo = New-Object System.IO.DriveInfo($outboxRoot)
    $freeGB = [math]::Round($outboxDriveInfo.AvailableFreeSpace / 1GB, 2)
    if ($outboxDriveInfo.AvailableFreeSpace -lt 10737418240) {
        Write-Warn "Outbox volume ($outboxRoot) has $freeGB GB free. Abodi TelemetryOutbox enforces a 10.0 GB minimum free space guard."
    } else {
        Write-Ok "Outbox volume ($outboxRoot) free space check passed ($freeGB GB available)."
    }
} catch {
    Write-Warn "Could not query free disk space on outbox volume '$outboxRoot'."
}

$outboxDbPath  = Join-Path $OutboxDir "abodi-telemetry.db"
$kdoujaBaseDir = Join-Path $StorageDir "kdouja"

if ($CheckOnly.IsPresent) {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host " Rokka Abodi Node Agent (v$AbodiReleaseVersion-GA) Pre-Flight Check Complete (Windows x64)" -ForegroundColor Green
    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host "  Service Name:         $ServiceName"
    Write-Host "  Node Code:            $NodeCode ($NodeCodeSource)"
    Write-Host "  Node Footprint:       $($nodeFootprint.CombinedId)"
    Write-Host "  Hardware Footprint:   $($nodeFootprint.HardwareSummary)"
    Write-Host "  Rokka Coordinator:    $RokkaUrl"
    Write-Host "  SPIFFE Trust Domain:  $TrustDomain (spiffe://$TrustDomain/node/$NodeCode)"
    Write-Host "  Kdouja Storage Mode:  $StorageMode $(if ($StorageMode -eq 'Standalone') { "($KdoujaEndpoint)" } else { "($kdoujaBaseDir)" })"
    Write-Host "  Install Directory:    $InstallDir"
    Write-Host "  Storage Directory:    $StorageDir"
    Write-Host "==============================================================================" -ForegroundColor Green
    exit 0
}

foreach ($dir in @($InstallDir, $RokkaData, $SecurityDir, $OutboxDir, $LogDir, $StorageDir)) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Set-RestrictedSecurityDirectoryAcl {
    param([string]$Path)
    $acl = Get-Acl -Path $Path
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $acl.Access) {
        $acl.RemoveAccessRule($rule) | Out-Null
    }

    $inheritFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    $propFlags    = [System.Security.AccessControl.PropagationFlags]::None

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
# Step 4: Stop Running Services/Processes & Deploy Abodi Application Binaries
# ------------------------------------------------------------------------------
function Stop-AbodiServicesAndProcesses {
    param(
        [string[]]$ServiceNames,
        [string]$TargetInstallDir
    )

    # 1. Stop Windows Services gracefully with timeout
    foreach ($svcName in $ServiceNames) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($null -ne $svc) {
            if ($svc.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
                Write-Info "Stopping Windows Service '$svcName' (Current status: $($svc.Status))..."
                try {
                    Stop-Service -Name $svcName -Force -NoWait -ErrorAction SilentlyContinue
                    $svc.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromSeconds(10))
                } catch {
                    Write-Warn "Service '$svcName' did not stop within 10s timeout; proceeding to force-terminate process..."
                }
            }
        }
    }

    # 2. Force-kill any running Abodi.exe process (service host, hung shutdown, or manual console instance)
    $abodiProcs = @(Get-Process -Name "Abodi" -ErrorAction SilentlyContinue)
    if ($abodiProcs.Count -gt 0) {
        $pids = ($abodiProcs | Select-Object -ExpandProperty Id) -join ", "
        Write-Info "Force-terminating active Abodi.exe process(es) [PID: $pids] to release file locks..."
        foreach ($proc in $abodiProcs) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $proc.WaitForExit(5000) | Out-Null
            } catch { }
        }
        & taskkill.exe /F /IM "Abodi.exe" /T 2>$null | Out-Null
        Start-Sleep -Seconds 1
        Write-Ok "Terminated running Abodi.exe process(es)."
    }

    # 3. Clean up any old renamed .old_* binaries from previous upgrades
    if (Test-Path $TargetInstallDir) {
        Get-ChildItem -Path $TargetInstallDir -Filter "*.old_*" -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function Copy-AbodiPayloadSafely {
    param(
        [string]$SourceDir,
        [string]$DestinationDir
    )

    Get-ChildItem -Path $SourceDir -Exclude @("logs", "*.db", "*.db-shm", "*.db-wal", "*.old_*") | ForEach-Object {
        $srcItem = $_
        $destPath = Join-Path $DestinationDir $srcItem.Name

        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                Copy-Item -Path $srcItem.FullName -Destination $DestinationDir -Recurse -Force -ErrorAction Stop
                break
            } catch {
                if ($attempt -eq 1) {
                    Write-Warn "File lock detected on '$destPath'; force-releasing process handles and unlocking via NTFS rename..."
                    Stop-AbodiServicesAndProcesses -ServiceNames @($ServiceName, $LegacyServiceName) -TargetInstallDir $DestinationDir
                    if (Test-Path $destPath -PathType Leaf) {
                        $backupLocked = "$destPath.old_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
                        try {
                            Move-Item -Path $destPath -Destination $backupLocked -Force -ErrorAction SilentlyContinue
                            Remove-Item -Path $backupLocked -Force -ErrorAction SilentlyContinue
                        } catch { }
                    }
                }
                Start-Sleep -Milliseconds 800
                if ($attempt -eq 3) {
                    throw
                }
            }
        }
    }
}

# Stop both Aarkam.Abodi and legacy Rokka.Abodi.Agent services + force-kill any lingering Abodi.exe processes
Stop-AbodiServicesAndProcesses -ServiceNames @($ServiceName, $LegacyServiceName) -TargetInstallDir $InstallDir

# Delete legacy Rokka.Abodi.Agent service registration if present
if ($null -ne (Get-Service -Name $LegacyServiceName -ErrorAction SilentlyContinue)) {
    Write-Info "Removing legacy Windows Service registration '$LegacyServiceName'..."
    & sc.exe delete $LegacyServiceName | Out-Null
    Write-Ok "Removed legacy Windows Service '$LegacyServiceName'."
}

$normalizedInstallDir = [System.IO.Path]::GetFullPath($InstallDir).TrimEnd('\', '/')

if (-not [string]::IsNullOrWhiteSpace($resolvedSourceDir)) {
    $normalizedSourceDir = [System.IO.Path]::GetFullPath($resolvedSourceDir).TrimEnd('\', '/')
    if ($normalizedSourceDir -ine $normalizedInstallDir) {
        Write-Info "Deploying Abodi v$AbodiReleaseVersion binaries from '$resolvedSourceDir' to '$InstallDir'..."
        Copy-AbodiPayloadSafely -SourceDir $resolvedSourceDir -DestinationDir $InstallDir
        Write-Ok "Deployed Abodi binaries to '$InstallDir'."
    } else {
        Write-Ok "Abodi binaries are already staged in target directory '$InstallDir'."
    }
} elseif (-not [string]::IsNullOrWhiteSpace($resolvedCsproj)) {
    Write-Info "Publishing Abodi single-file executable from '$resolvedCsproj'..."
    & dotnet publish $resolvedCsproj -f "net10.0" -c Release -r win-x64 --self-contained true `
        /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true `
        /p:EnableCompressionInSingleFile=true /p:Version=$AbodiReleaseVersion -o $InstallDir
    Write-Ok "Published Abodi to '$InstallDir'."
} elseif ((Test-Path (Join-Path $InstallDir "Abodi.exe")) -or (Test-Path (Join-Path $InstallDir "Abodi.dll"))) {
    Write-Ok "Existing Abodi binaries detected in '$InstallDir'."
} else {
    Write-Warn "No source or pre-published binaries found. Copy Abodi.exe to '$InstallDir' before starting the service."
}

if (-not [string]::IsNullOrWhiteSpace($tempZipExtract) -and (Test-Path $tempZipExtract)) {
    Remove-Item -Path $tempZipExtract -Recurse -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# Step 5: Provision Single-Use Bootstrap Enrollment Token & Credentials
# ------------------------------------------------------------------------------
$BootstrapTokenPath = Join-Path $SecurityDir "bootstrap-enrollment.token"

if (-not [string]::IsNullOrWhiteSpace($TokenFile)) {
    if (-not (Test-Path $TokenFile)) {
        Write-Err "Specified -TokenFile '$TokenFile' does not exist."
        exit 1
    }
    $EnrollmentToken = (Get-Content -Path $TokenFile -Raw).Trim()
    [System.IO.File]::WriteAllBytes($TokenFile, (New-Object byte[] 64))
    Remove-Item -Path $TokenFile -Force
    Write-Ok "Read and securely scrubbed external token file '$TokenFile'."
}

if (-not [string]::IsNullOrWhiteSpace($EnrollmentToken)) {
    [System.IO.File]::WriteAllText($BootstrapTokenPath, $EnrollmentToken.Trim())
    $EnrollmentToken = $null
    Write-Ok "Provisioned single-use enrollment token at $BootstrapTokenPath (auto-scrubbed on first boot)."
}

# ------------------------------------------------------------------------------
# Step 6: Persist NodeCode to appsettings.json & Generate appsettings.Production.json
# ------------------------------------------------------------------------------
$allowOsBool = if ($AllowOsPartition.IsPresent) { $true } else { $false }
$directIoBool = if ($DisableDirectIO.IsPresent) { $false } else { $true }

# Ensure base appsettings.json in $InstallDir stores the resolved/generated NodeCode
$baseAppSettingsPath = Join-Path $InstallDir "appsettings.json"
if (Test-Path $baseAppSettingsPath -PathType Leaf) {
    try {
        $baseObj = (Get-Content -Path $baseAppSettingsPath -Raw) | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $baseObj.AgentConfiguration) {
            $baseObj.AgentConfiguration.NodeCode = $NodeCode
            $baseObj | ConvertTo-Json -Depth 6 | Set-Content -Path $baseAppSettingsPath -Encoding UTF8
            Write-Ok "Persisted NodeCode '$NodeCode' in $baseAppSettingsPath"
        }
    } catch { }
}

$agentConfigMap = @{
    NodeCode = $NodeCode
    RokkaUrl = $RokkaUrl
    LocalStorageGrpcUrl = "http://127.0.0.1:7775"
    TelemetryIntervalSeconds = 10
    HeartbeatIntervalSeconds = 15
    ManifestCacheHours = 6
}
if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    $agentConfigMap["ApiKey"] = $ApiKey.Trim()
}
if (-not [string]::IsNullOrWhiteSpace($MasterKeyFile)) {
    $agentConfigMap["MasterKeyFile"] = $MasterKeyFile.Trim()
}

$prodConfig = @{
    SerilogConfig = @{
        MinimumLevel = "Information"
        WriteToConsole = $true
        WriteToFile = $true
        LogDirectory = $LogDir
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
    AgentConfiguration = $agentConfigMap
    Cluster = @{
        TrustDomain = $TrustDomain
    }
    Security = @{
        TrustDomain = $TrustDomain
        IdentityStorageDirectory = $SecurityDir
        EnrollmentTokenFile = $BootstrapTokenPath
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
        EnableDirectIO = $directIoBool
    }
    Kdouja = @{
        Mode = $StorageMode
        Embedded = @{
            BaseDirectory = $kdoujaBaseDir
            EnableDirectIO = $directIoBool
            PageSizeBytes = 4096
            EnableWalFsync = $true
        }
        Standalone = @{
            Endpoint = $KdoujaEndpoint
            EnableRetry = $true
        }
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
Write-Ok "Generated production configuration at $configPath (NodeCode = $NodeCode, Kdouja:Mode = $StorageMode)"

# ------------------------------------------------------------------------------
# Step 7: Configure Windows Defender Firewall
# ------------------------------------------------------------------------------
if (-not $SkipFirewall.IsPresent) {
    Write-Info "Configuring Windows Defender Firewall rules for Abodi mTLS ports (57775, 57776)..."
    $ruleNameGrpc = "Aarkam Abodi gRPC mTLS (57775)"
    $ruleNameRest = "Aarkam Abodi REST HTTPS (57776)"

    if (-not (Get-NetFirewallRule -DisplayName $ruleNameGrpc -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleNameGrpc -Direction Inbound -Protocol TCP -LocalPort 57775 -Action Allow -Profile Any | Out-Null
    }
    if (-not (Get-NetFirewallRule -DisplayName $ruleNameRest -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleNameRest -Direction Inbound -Protocol TCP -LocalPort 57776 -Action Allow -Profile Any | Out-Null
    }
    Write-Ok "Windows Defender Firewall rules configured."
}

# ------------------------------------------------------------------------------
# Step 8: Register & Start Windows Service ('Aarkam.Abodi') + Verify Health Probes
# ------------------------------------------------------------------------------
[Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Production", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT", "1", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ROKKA_IDENTITY_STORAGE_DIR", $SecurityDir, [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ROKKA_ENROLLMENT_TOKEN_FILE", $BootstrapTokenPath, [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ABODI_ALLOW_OS_PARTITION", $allowOsBool.ToString().ToLowerInvariant(), [EnvironmentVariableTarget]::Machine)

$exePath = Join-Path $InstallDir "Abodi.exe"
$dllPath = Join-Path $InstallDir "Abodi.dll"
$dotnetExe = Join-Path $env:ProgramFiles "dotnet\dotnet.exe"

$binPath = if (Test-Path $exePath) { "`"$exePath`"" } else { "`"$dotnetExe`" `"$dllPath`"" }

if ($null -eq (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    Write-Info "Registering Windows Service '$ServiceName'..."
    New-Service -Name $ServiceName `
        -DisplayName "Aarkam Abodi Zero-Trust Node Agent" `
        -BinaryPathName $binPath `
        -StartupType Automatic `
        -Description "Aarkam Abodi Sovereign Storage Node Agent, Dual-Mode Kdouja SAT Gateway, Hardware Telemetry & Zero-Trust mTLS Daemon" | Out-Null
} else {
    & sc.exe config $ServiceName binPath= $binPath start= auto | Out-Null
}

& sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/5000/restart/5000 | Out-Null
Write-Ok "Registered Windows Service '$ServiceName' (Binary: $binPath)."

$shouldStart = (-not $SkipStartService.IsPresent) -or $StartService.IsPresent
if ($shouldStart -and ((Test-Path $exePath) -or (Test-Path $dllPath))) {
    Write-Info "Starting Windows Service '$ServiceName'..."
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 3
    $svcState = Get-Service -Name $ServiceName
    if ($svcState.Status -eq "Running") {
        Write-Ok "Service '$ServiceName' is active and running."

        try {
            $pingResp = Invoke-WebRequest -Uri "http://127.0.0.1:7776/api/v1/health/ping" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            Write-Ok "Abodi Liveness Probe (/api/v1/health/ping) returned HTTP $($pingResp.StatusCode)."
        } catch {
            Write-Warn "Liveness probe not yet responding on http://127.0.0.1:7776/api/v1/health/ping (service may still be initializing)."
        }

        try {
            $kdoujaResp = Invoke-WebRequest -Uri "http://127.0.0.1:7776/healthz/kdouja" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            Write-Ok "Kdouja SAT Storage Probe (/healthz/kdouja, Mode=$StorageMode) returned HTTP $($kdoujaResp.StatusCode)."
        } catch {
            Write-Warn "Kdouja health check (/healthz/kdouja) returned warning or is still warming up: $($_.Exception.Message)"
        }
    } else {
        Write-Err "Service '$ServiceName' did not reach Running state (Current: $($svcState.Status)). Check logs in '$LogDir' or Windows Event Viewer."
        exit 1
    }
} elseif ($SkipStartService.IsPresent) {
    Write-Info "Skipped service startup (-SkipStartService). Start manually via: Start-Service -Name '$ServiceName'"
} else {
    Write-Warn "Abodi binaries are not yet in $InstallDir. Copy binaries and run: Start-Service -Name '$ServiceName'"
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host " Rokka Abodi Node Agent (v$AbodiReleaseVersion-GA) Installation Complete (Windows x64)" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  Service Name:         $ServiceName"
Write-Host "  Node Code:            $NodeCode ($NodeCodeSource)"
Write-Host "  Node Footprint:       $($nodeFootprint.CombinedId)"
Write-Host "  Hardware Footprint:   $($nodeFootprint.HardwareSummary)"
Write-Host "  Rokka Coordinator:    $RokkaUrl"
Write-Host "  SPIFFE Trust Domain:  $TrustDomain (spiffe://$TrustDomain/node/$NodeCode)"
Write-Host "  Kdouja Storage Mode:  $StorageMode $(if ($StorageMode -eq 'Standalone') { "($KdoujaEndpoint)" } else { "($kdoujaBaseDir)" })"
Write-Host "  Install Directory:    $InstallDir"
Write-Host "  Zero-Trust Key Store: $SecurityDir (Protected NTFS ACL)"
Write-Host "  SQLite WAL Outbox:    $outboxDbPath"
Write-Host "  Storage Directory:    $StorageDir"
Write-Host "  Log Directory:        $LogDir"
Write-Host "  Service Status:       Get-Service -Name '$ServiceName'"
Write-Host "  Liveness Probe:       curl.exe -s http://127.0.0.1:7776/api/v1/health/ping"
Write-Host "  Kdouja Health Probe:  curl.exe -s http://127.0.0.1:7776/healthz/kdouja"
Write-Host "==============================================================================" -ForegroundColor Green
