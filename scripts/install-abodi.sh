#!/usr/bin/env bash
# ==============================================================================
# Rokka Abodi Node Agent — Automated Production Installation & Bootstrap Script
# ==============================================================================
# Target OS:   Ubuntu 22.04 / 24.04 LTS, Debian 12+, RHEL / Rocky / AlmaLinux 9+
# Runtime:     .NET 10.0 ASP.NET Core Runtime
# Security:    Rokka-Only Zero-Trust mTLS Node Identity, POSIX 0700/0600 Isolation,
#              Single-Use Enrollment Token Provisioning & Scrubbing
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Default Configuration & Paths
# ------------------------------------------------------------------------------
INSTALL_DIR="/opt/rokka/abodi"
CONFIG_DIR="/etc/rokka/abodi"
DATA_DIR="/var/lib/rokka"
SECURITY_DIR="/var/lib/rokka/security"
OUTBOX_DIR="/var/lib/rokka/outbox"
STORAGE_DIR="/var/lib/rokka/storage"
LOG_DIR="/var/log/rokka/abodi"
SERVICE_USER="rokka"
SERVICE_GROUP="rokka"
SERVICE_NAME="rokka-abodi"

NODE_CODE="$(hostname -s)"
ROKKA_URL="https://rokka-coordinator.aarkam:57774"
TRUST_DOMAIN="rokka.cluster"
ENROLLMENT_TOKEN=""
ENROLLMENT_TOKEN_FILE=""
BINARY_SOURCE=""
ALLOW_OS_PARTITION="false"
ENABLE_DIRECT_IO="true"
SKIP_SYSCTL="false"
SKIP_FIREWALL="false"
RUN_AS_ROOT="false"

# ------------------------------------------------------------------------------
# Output Formatting Helpers
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat <<EOF
Usage: sudo ./install-abodi.sh [OPTIONS]

Automated production installer for the Rokka Abodi Storage & Diagnostics Node Agent.
Abodi registers exclusively with the Rokka Storage Coordinator (Zero dependency on Aarkam.IO).

Options:
  --node-code <id>           Unique node identifier (default: system short hostname: ${NODE_CODE})
  --rokka-url <url>          Rokka Coordinator endpoint (default: ${ROKKA_URL})
  --trust-domain <domain>    Zero-Trust SPIFFE trust domain (default: ${TRUST_DOMAIN})
  --enrollment-token <tok>   Single-use Rokka bootstrap token (ET1.<hex>) for initial mTLS CSR enrollment
  --token-file <path>        Path to file containing the single-use enrollment token (scrubbed after bootstrap)
  --source <path>            Path to pre-published Abodi binaries or repository root to build from
  --storage-dir <path>       Primary storage mount directory (default: ${STORAGE_DIR})
  --allow-os-partition       Permit storage allocation on the OS root partition (evaluation/dev only)
  --run-as-root              Run systemd service as root instead of dedicated '${SERVICE_USER}' account
  --skip-sysctl              Skip Linux kernel and NVMe I/O scheduler tuning
  --skip-firewall            Skip UFW / firewalld port configuration
  -h, --help                 Display this help message

Examples:
  # Standard Production Installation with Sovereign Cluster URL:
  sudo ./install-abodi.sh \\
    --node-code "node-prod-042" \\
    --rokka-url "https://rokka-coordinator.aarkam:57774" \\
    --enrollment-token "ET1.a8f9..."

  # Standard Port 443 via Ingress / Reverse Proxy:
  sudo ./install-abodi.sh \\
    --node-code "node-prod-043" \\
    --rokka-url "https://rokka-coordinator.aarkam" \\
    --enrollment-token "ET1.a8f9..."

  # On-Premises IP Address:
  sudo ./install-abodi.sh \\
    --node-code "node-prod-044" \\
    --rokka-url "https://10.20.0.10:57774" \\
    --enrollment-token "ET1.a8f9..."

  # Local Development / Single Machine:
  sudo ./install-abodi.sh \\
    --node-code "node-dev-01" \\
    --rokka-url "https://localhost:57774" \\
    --enrollment-token "ET1.a8f9..." \\
    --allow-os-partition
EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Parse Command-Line Arguments
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --node-code)          NODE_CODE="$2"; shift 2 ;;
        --rokka-url)          ROKKA_URL="$2"; shift 2 ;;
        --trust-domain)       TRUST_DOMAIN="$2"; shift 2 ;;
        --enrollment-token)   ENROLLMENT_TOKEN="$2"; shift 2 ;;
        --token-file)         ENROLLMENT_TOKEN_FILE="$2"; shift 2 ;;
        --source)             BINARY_SOURCE="$2"; shift 2 ;;
        --storage-dir)        STORAGE_DIR="$2"; shift 2 ;;
        --allow-os-partition) ALLOW_OS_PARTITION="true"; shift ;;
        --run-as-root)        RUN_AS_ROOT="true"; shift ;;
        --skip-sysctl)        SKIP_SYSCTL="true"; shift ;;
        --skip-firewall)      SKIP_FIREWALL="true"; shift ;;
        -h|--help)            usage ;;
        *)                    log_error "Unknown option: $1"; usage ;;
    esac
done

# Normalize Rokka Coordinator URL
if [[ "$ROKKA_URL" != http://* && "$ROKKA_URL" != https://* ]]; then
    ROKKA_URL="https://${ROKKA_URL}"
fi
log_info "Target Rokka Coordinator endpoint: ${ROKKA_URL}"

# ------------------------------------------------------------------------------
# Step 1: Root & Operating System Pre-Flight Checks
# ------------------------------------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    log_error "This installer must be executed with root privileges (use sudo)."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect Linux distribution (/etc/os-release is missing)."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
OS_ID="${ID:-unknown}"
OS_VERSION="${VERSION_ID:-unknown}"
ARCH="$(uname -m)"
KERNEL_REL="$(uname -r)"

log_info "Detected OS: ${PRETTY_NAME:-$OS_ID} | Kernel: ${KERNEL_REL} | Arch: ${ARCH}"

# Verify minimum RAM (2 GB minimum, 8 GB+ recommended)
TOTAL_MEM_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
TOTAL_MEM_MB="$((TOTAL_MEM_KB / 1024))"
if (( TOTAL_MEM_MB < 1800 )); then
    log_warn "Host has ${TOTAL_MEM_MB} MB RAM. Minimum required for Abodi is 2,048 MB (8,192 MB+ recommended for production)."
else
    log_ok "Memory check passed: ${TOTAL_MEM_MB} MB RAM available."
fi

# ------------------------------------------------------------------------------
# Step 2: Install Hardware & System Dependencies
# ------------------------------------------------------------------------------
log_info "Installing hardware telemetry & storage prerequisite packages..."

install_debian_ubuntu_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq \
        curl wget ca-certificates gnupg lsb-release apt-transport-https \
        smartmontools nvme-cli util-linux pciutils dmidecode lm-sensors \
        iproute2 ethtool libsqlite3-0 libicu-dev libssl3 acl libcap2-bin
}

install_rhel_deps() {
    dnf install -y -q \
        curl wget ca-certificates gnupg2 \
        smartmontools nvme-cli util-linux pciutils dmidecode lm_sensors \
        iproute ethtool sqlite-libs libicu openssl-libs acl libcap
}

case "${OS_ID}" in
    ubuntu|debian)
        install_debian_ubuntu_deps
        ;;
    rhel|rocky|almalinux|centos|fedora)
        install_rhel_deps
        ;;
    *)
        log_warn "Unrecognized distribution '${OS_ID}'. Attempting generic package check..."
        ;;
esac

# Verify critical CLI utilities used by Abodi collectors
for cmd in lsblk smartctl nvme setcap; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        log_ok "Verified required utility: $(command -v "${cmd}")"
    else
        log_error "Required utility '${cmd}' is missing after package installation."
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# Step 3: Verify / Install .NET 10.0 ASP.NET Core Runtime
# ------------------------------------------------------------------------------
install_dotnet_10() {
    if command -v dotnet >/dev/null 2>&1; then
        if dotnet --list-runtimes 2>/dev/null | grep -q "Microsoft.AspNetCore.App 10\."; then
            log_ok ".NET 10.0 ASP.NET Core Runtime is already installed."
            return 0
        fi
    fi

    log_info "Installing .NET 10.0 ASP.NET Core Runtime via Microsoft official installer..."
    local install_script="/tmp/dotnet-install.sh"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "${install_script}"
    chmod +x "${install_script}"
    "${install_script}" --channel 10.0 --runtime aspnetcore --install-dir /usr/share/dotnet
    ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet
    rm -f "${install_script}"

    if dotnet --list-runtimes 2>/dev/null | grep -q "Microsoft.AspNetCore.App 10\."; then
        log_ok ".NET 10.0 ASP.NET Core Runtime installed successfully."
    else
        log_error "Failed to verify .NET 10.0 ASP.NET Core Runtime installation."
        exit 1
    fi
}

install_dotnet_10

# ------------------------------------------------------------------------------
# Step 4: Create Dedicated Service Account & Zero-Trust Directory Hierarchy
# ------------------------------------------------------------------------------
log_info "Provisioning service account and isolated Zero-Trust filesystem layout..."

if ! getent group "${SERVICE_GROUP}" >/dev/null 2>&1; then
    groupadd --system "${SERVICE_GROUP}"
fi

if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
    useradd --system \
        --gid "${SERVICE_GROUP}" \
        --home-dir "${DATA_DIR}" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        --comment "Rokka Abodi Storage & Diagnostics Daemon" \
        "${SERVICE_USER}"
    log_ok "Created system user '${SERVICE_USER}'."
fi

# Add service user to 'disk' group so it can inspect block devices (/dev/nvme*, /dev/sd*)
if getent group disk >/dev/null 2>&1; then
    usermod -aG disk "${SERVICE_USER}"
fi

mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${SECURITY_DIR}" "${OUTBOX_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"

# Enforce strict POSIX permissions:
# /var/lib/rokka/security MUST be 0700 (stores ECDSA P-256 private key node-identity.key)
chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"
chmod 0750 "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${OUTBOX_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"
chmod 0700 "${SECURITY_DIR}"

# Grant Linux capabilities to smartctl so non-root service account can query SMART/NVMe health registers
SMARTCTL_BIN="$(command -v smartctl)"
if [[ -n "${SMARTCTL_BIN}" ]]; then
    setcap 'cap_sys_rawio,cap_sys_admin+ep' "${SMARTCTL_BIN}" || log_warn "Could not set capabilities on ${SMARTCTL_BIN}"
    log_ok "Granted cap_sys_rawio,cap_sys_admin to ${SMARTCTL_BIN}"
fi

# ------------------------------------------------------------------------------
# Step 5: Deploy or Build Abodi Application Binaries
# ------------------------------------------------------------------------------
deploy_binaries() {
    if [[ -n "${BINARY_SOURCE}" ]]; then
        if [[ -f "${BINARY_SOURCE}/Abodi.dll" ]]; then
            log_info "Copying pre-published Abodi binaries from '${BINARY_SOURCE}'..."
            cp -a "${BINARY_SOURCE}/." "${INSTALL_DIR}/"
        elif [[ -f "${BINARY_SOURCE}/src/Abodi/Abodi.csproj" ]]; then
            log_info "Building Abodi from source repository '${BINARY_SOURCE}'..."
            dotnet publish "${BINARY_SOURCE}/src/Abodi/Abodi.csproj" \
                -c Release \
                -o "${INSTALL_DIR}" \
                /p:UseAppHost=false
        else
            log_error "Invalid --source path '${BINARY_SOURCE}'. Expected directory containing Abodi.dll or src/Abodi/Abodi.csproj."
            exit 1
        fi
    elif [[ -f "./Abodi.dll" ]]; then
        log_info "Copying Abodi binaries from current directory..."
        cp -a ./* "${INSTALL_DIR}/"
    elif [[ -f "./src/Abodi/Abodi.csproj" ]]; then
        log_info "Publishing Abodi from current repository root..."
        dotnet publish "./src/Abodi/Abodi.csproj" \
            -c Release \
            -o "${INSTALL_DIR}" \
            /p:UseAppHost=false
    else
        log_warn "No local binaries or source tree specified (--source). Ensure Abodi binaries are placed in ${INSTALL_DIR} before starting the service."
    fi

    chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}"
}

deploy_binaries

# ------------------------------------------------------------------------------
# Step 6: Provision Single-Use Bootstrap Enrollment Token (Zero-Trust Hygiene)
# ------------------------------------------------------------------------------
BOOTSTRAP_TOKEN_PATH="${SECURITY_DIR}/bootstrap-enrollment.token"

if [[ -n "${ENROLLMENT_TOKEN_FILE}" ]]; then
    if [[ ! -f "${ENROLLMENT_TOKEN_FILE}" ]]; then
        log_error "Specified --token-file '${ENROLLMENT_TOKEN_FILE}' does not exist."
        exit 1
    fi
    ENROLLMENT_TOKEN="$(tr -d '[:space:]' < "${ENROLLMENT_TOKEN_FILE}")"
    # Securely shred/delete the source token file immediately
    if command -v shred >/dev/null 2>&1; then
        shred -u "${ENROLLMENT_TOKEN_FILE}" 2>/dev/null || rm -f "${ENROLLMENT_TOKEN_FILE}"
    else
        rm -f "${ENROLLMENT_TOKEN_FILE}"
    fi
    log_ok "Read and scrubbed external token file '${ENROLLMENT_TOKEN_FILE}'."
fi

if [[ -n "${ENROLLMENT_TOKEN}" ]]; then
    # Write token to 0600 protected file inside /var/lib/rokka/security/
    # Never pass the token on the process command line or persistent systemd unit!
    # NodeEnrollmentBootstrapWorker automatically deletes this file upon enrollment.
    umask 0077
    printf "%s" "${ENROLLMENT_TOKEN}" > "${BOOTSTRAP_TOKEN_PATH}"
    chown "${SERVICE_USER}:${SERVICE_GROUP}" "${BOOTSTRAP_TOKEN_PATH}"
    chmod 0600 "${BOOTSTRAP_TOKEN_PATH}"
    unset ENROLLMENT_TOKEN
    log_ok "Provisioned single-use enrollment token at ${BOOTSTRAP_TOKEN_PATH} (mode 0600; auto-scrubbed on first boot)."
fi

# ------------------------------------------------------------------------------
# Step 7: Generate Production Configuration
# ------------------------------------------------------------------------------
log_info "Generating production configuration in ${CONFIG_DIR}/appsettings.Production.json..."

cat > "${CONFIG_DIR}/appsettings.Production.json" <<EOF
{
  "SerilogConfig": {
    "WriteToFile": true,
    "FileRetentionDays": 30,
    "WriteToSeq": false,
    "SeqUrl": "http://localhost:5341",
    "WriteToElasticsearch": false,
    "ElasticsearchUrl": "http://localhost:9200"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.Hosting.Lifetime": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AgentConfiguration": {
    "NodeCode": "${NODE_CODE}",
    "RokkaUrl": "${ROKKA_URL}",
    "TelemetryIntervalSeconds": 10,
    "HeartbeatIntervalSeconds": 15,
    "ManifestCacheHours": 6
  },
  "Cluster": {
    "TrustDomain": "${TRUST_DOMAIN}"
  },
  "Security": {
    "TrustDomain": "${TRUST_DOMAIN}",
    "IdentityStorageDirectory": "${SECURITY_DIR}",
    "EnrollmentTokenFilePath": "${BOOTSTRAP_TOKEN_PATH}"
  },
  "TelemetryOutbox": {
    "DatabasePath": "${OUTBOX_DIR}/abodi-telemetry.db",
    "MaxQueuedRecords": 50000,
    "MaxQueueSizeBytes": 52428800,
    "RetentionTtlHours": 72,
    "MaxRetries": 10,
    "MinFreeDiskSpaceBytes": 10737418240
  },
  "Storage": {
    "Address": "https://0.0.0.0:57775",
    "CoordinatorAddress": "${ROKKA_URL}",
    "DataDirectory": "${STORAGE_DIR}",
    "AllowOsPartition": ${ALLOW_OS_PARTITION},
    "EnableDirectIO": ${ENABLE_DIRECT_IO}
  },
  "Kestrel": {
    "Endpoints": {
      "Rest-Https": {
        "Url": "https://0.0.0.0:57776",
        "Protocols": "Http1AndHttp2"
      },
      "Rest-Http": {
        "Url": "http://127.0.0.1:7776",
        "Protocols": "Http1"
      },
      "gRPC-Https": {
        "Url": "https://0.0.0.0:57775",
        "Protocols": "Http1AndHttp2"
      },
      "gRPC-Http": {
        "Url": "http://127.0.0.1:7775",
        "Protocols": "Http2"
      }
    }
  }
}
EOF

chown "${SERVICE_USER}:${SERVICE_GROUP}" "${CONFIG_DIR}/appsettings.Production.json"
chmod 0640 "${CONFIG_DIR}/appsettings.Production.json"
ln -sf "${CONFIG_DIR}/appsettings.Production.json" "${INSTALL_DIR}/appsettings.Production.json"

# ------------------------------------------------------------------------------
# Step 8: Apply Linux Kernel & NVMe I/O Scheduler Tuning
# ------------------------------------------------------------------------------
if [[ "${SKIP_SYSCTL}" == "false" ]]; then
    log_info "Applying production Linux kernel & storage sysctl tuning..."
    cat > /etc/sysctl.d/99-rokka-abodi.conf <<EOF
# Rokka Abodi Storage & Telemetry Node Kernel Tuning
fs.file-max = 2097152
fs.aio-max-nr = 1048576
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.swappiness = 1
vm.max_map_count = 262144
net.core.somaxconn = 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_tw_reuse = 1
EOF
    sysctl --system >/dev/null 2>&1 || log_warn "Some sysctl parameters could not be applied (containerized environment?)."

    # Set NVMe scheduler to 'none' for low-latency Direct I/O
    for sched in /sys/block/nvme*/queue/scheduler; do
        if [[ -w "${sched}" ]]; then
            echo none > "${sched}" 2>/dev/null || true
        fi
    done
    log_ok "Applied sysctl parameters and NVMe queue scheduler optimizations."
fi

# ------------------------------------------------------------------------------
# Step 9: Configure systemd Service Unit with Hardened Sandboxing
# ------------------------------------------------------------------------------
log_info "Creating hardened systemd unit /etc/systemd/system/${SERVICE_NAME}.service..."

SVC_USER="${SERVICE_USER}"
SVC_GROUP="${SERVICE_GROUP}"
if [[ "${RUN_AS_ROOT}" == "true" ]]; then
    SVC_USER="root"
    SVC_GROUP="root"
fi

cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Rokka Abodi Zero-Trust Storage & Hardware Diagnostics Node Agent
Documentation=https://rokka.internal/docs/abodi
After=network-online.target local-fs.target
Wants=network-online.target

[Service]
Type=simple
User=${SVC_USER}
Group=${SVC_GROUP}
SupplementaryGroups=disk
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/dotnet ${INSTALL_DIR}/Abodi.dll
Restart=always
RestartSec=5s
TimeoutStopSec=30s

# Resource Limits
LimitNOFILE=1048576
LimitMEMLOCK=infinity
TasksMax=infinity

# Environment Configuration
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ROKKA_IDENTITY_STORAGE_DIR=${SECURITY_DIR}
Environment=ROKKA_ENROLLMENT_TOKEN_FILE=${BOOTSTRAP_TOKEN_PATH}
Environment=ABODI_ALLOW_OS_PARTITION=${ALLOW_OS_PARTITION}

# Linux Capabilities for Hardware SMART & NVMe Telemetry
AmbientCapabilities=CAP_SYS_RAWIO CAP_SYS_ADMIN
CapabilityBoundingSet=CAP_SYS_RAWIO CAP_SYS_ADMIN CAP_DAC_READ_SEARCH CAP_NET_BIND_SERVICE

# Filesystem & Process Hardening
NoNewPrivileges=false
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
ReadWritePaths=${DATA_DIR} ${SECURITY_DIR} ${OUTBOX_DIR} ${STORAGE_DIR} ${LOG_DIR} ${CONFIG_DIR}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
log_ok "Registered and enabled systemd service '${SERVICE_NAME}.service'."

# ------------------------------------------------------------------------------
# Step 10: Configure Host Firewall (UFW / firewalld)
# ------------------------------------------------------------------------------
if [[ "${SKIP_FIREWALL}" == "false" ]]; then
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        log_info "Configuring UFW firewall rules for Abodi mTLS ports (57775/tcp, 57776/tcp)..."
        ufw allow 57775/tcp comment "Rokka Abodi gRPC mTLS" >/dev/null
        ufw allow 57776/tcp comment "Rokka Abodi REST HTTPS" >/dev/null
        log_ok "UFW rules updated."
    elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
        log_info "Configuring firewalld rules for Abodi mTLS ports (57775/tcp, 57776/tcp)..."
        firewall-cmd --permanent --add-port=57775/tcp >/dev/null
        firewall-cmd --permanent --add-port=57776/tcp >/dev/null
        firewall-cmd --reload >/dev/null
        log_ok "firewalld rules updated."
    fi
fi

# ------------------------------------------------------------------------------
# Step 11: Start Service & Verify Health if Binaries Present
# ------------------------------------------------------------------------------
if [[ -f "${INSTALL_DIR}/Abodi.dll" ]]; then
    log_info "Starting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service"
    sleep 3

    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
        log_ok "${SERVICE_NAME} is active and running."
    else
        log_error "${SERVICE_NAME} failed to start. Inspect logs via: sudo journalctl -u ${SERVICE_NAME} -n 100 --no-pager"
        exit 1
    fi
else
    log_warn "Abodi.dll not yet present in ${INSTALL_DIR}. Service is configured and enabled; start it after copying binaries:"
    log_warn "  sudo systemctl start ${SERVICE_NAME}"
fi

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN} Rokka Abodi Node Agent Installation Complete${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo "  Node Code:            ${NODE_CODE}"
echo "  Rokka Coordinator:    ${ROKKA_URL}"
echo "  Binary Directory:     ${INSTALL_DIR}"
echo "  Configuration File:   ${CONFIG_DIR}/appsettings.Production.json"
echo "  Zero-Trust Key Store: ${SECURITY_DIR} (mode 0700)"
echo "  SQLite WAL Outbox:    ${OUTBOX_DIR}/abodi-telemetry.db"
echo "  Service Status:       sudo systemctl status ${SERVICE_NAME}"
echo "  Live Logs:            sudo journalctl -u ${SERVICE_NAME} -f"
echo -e "${GREEN}==============================================================================${NC}"
