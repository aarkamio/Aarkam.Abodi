#!/usr/bin/env bash
# ==============================================================================
# Aarkam Abodi Node Agent (v1.0.4-GA) — Automated Production Installation Script
# ==============================================================================
# Target OS:   Ubuntu 22.04 / 24.04 LTS, Debian 12+, RHEL / Rocky / AlmaLinux 9+
# Service:     Aarkam.Abodi (systemd unit Aarkam.Abodi.service)
# Runtime:     Self-Contained Single-File .NET 10.0 Native Binary (or .NET 10 Runtime)
# Storage:     Dual-Mode Kdouja SAT (Embedded In-Process or Standalone kdoujad v1.0.2)
# Security:    Rokka-Only Zero-Trust mTLS Node Identity (spiffe://aarkam.cluster/node/*),
#              POSIX 0700/0600 Isolation, Single-Use Enrollment Token Scrubbing
# ==============================================================================

set -Eeuo pipefail

ABODI_RELEASE_VERSION="1.0.4"
REQUIRED_ROKKA_MIN_VERSION="1.0.2"
REQUIRED_KDOUJA_SAT_VERSION="1.0.2"
REQUIRED_KDOUJA_SDK_VERSION="1.0.1"
REQUIRED_KDOUJA_PRIM_VERSION="1.0.6"
REQUIRED_AM_CLI_MIN_VERSION="1.0.2"

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
SERVICE_NAME="Aarkam.Abodi"
LEGACY_SERVICE_NAME="rokka-abodi"

HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
NODE_CODE=""
NODE_CODE_SOURCE=""
ROKKA_URL="https://rokka-coordinator.aarkam:57774"
TRUST_DOMAIN="aarkam.cluster"
ENROLLMENT_TOKEN=""
ENROLLMENT_TOKEN_FILE=""
API_KEY=""
MASTER_KEY_FILE=""
BINARY_SOURCE=""
STORAGE_MODE="Embedded"
KDOUJA_ENDPOINT="http://127.0.0.1:57771"
ALLOW_OS_PARTITION="false"
ENABLE_DIRECT_IO="true"
SKIP_SYSCTL="false"
SKIP_FIREWALL="false"
SKIP_START="false"
RUN_AS_ROOT="false"
OFFLINE_MODE="false"
CHECK_ONLY="false"

# Official Aarkam Root Public Key DER Hex (matches SovereignLicenseVerifier.OfficialAarkamRootPublicKeyBytes)
AARKAM_ROOT_PUBKEY_HEX="30820222300d06092a864886f70d01010105000382020f003082020a0282020100c28d6915054cc67e5887a6e1035a376db57ce290e7a45455d4e823d2a34396dc5f155071c90e95cbe429f7177b7b35a3f033e4509f65ee30c4a40f170dbc2136257b39399cdce4a7faea53cc49e530716b54150273e2cb76e855c83616125ab18d65511562512712c931acf69811693bceb7c2421db772443ec6c00be49dd117588358a5ada90923a207d9dbce920c412645127c7283aa6957e295e1fbe7f2d8649b0d151b2eff5b25aff3eb5ced8726e65a2b160fae20b56787c42f30708a725bc965bea654078dd7e53bc245a7eef6175bd6b6d25acf38b24d481562cf25b9ec12f21e39e8c558c1587d9e18444974c4c34c772a142233b9b70ff23520b197a48a3e052c1de329bb39dee2b780593282c11af3b8d8d8b5bb2afb019f605a907e2b236eb4d28d9b795c0db1271966d9bad45373179ce223c6e7c39cb0d58d912006cadc578ccf0675e8fb4725ec2e7420425f14e1a31b9472ca4875579a04c0b0942380937cb0a20fdbe18c66fb0f30083b0925bed4ac3ffc9fd9a47ba95940587c3cec8802d78b02ebf1dae73608b971a165f0dfb17ad59072d81de07ef242870e23c51060243e6be59d8c783c65aa11e2f751e514a800cf04e0284ca6d6602ec84d16a134cb3291eb8ca4a49ae852f73f8dde798508b08185f645d38d1fd01811f35c23cf16a6ad0281d3e4c3383f246b06849c7450a7af987563309f81090203010001"

# ------------------------------------------------------------------------------
# Output Formatting Helpers
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ------------------------------------------------------------------------------
# Helper: Generate Random 15-Char NodeCode (XXXX-XXXX-XXXXX, >=1 digit per part)
# ------------------------------------------------------------------------------
generate_random_node_part() {
    local len="$1"
    local part=""
    while true; do
        part="$(LC_ALL=C tr -dc '0-9A-Z' < /dev/urandom | head -c "${len}" || true)"
        if [[ "${#part}" -eq "${len}" && "${part}" =~ [0-9] && "${part}" =~ [A-Z] ]]; then
            echo "${part}"
            return 0
        fi
    done
}

generate_random_node_code() {
    local p1 p2 p3
    p1="$(generate_random_node_part 4)"
    p2="$(generate_random_node_part 4)"
    p3="$(generate_random_node_part 5)"
    echo "${p1}-${p2}-${p3}"
}

# ------------------------------------------------------------------------------
# Helper: Extract NodeCode from existing appsettings.json / appsettings.Production.json
# ------------------------------------------------------------------------------
extract_node_code_from_file() {
    local file="$1"
    if [[ ! -f "${file}" ]]; then
        return 1
    fi
    local val
    val="$(grep -oE '"NodeCode"[[:space:]]*:[[:space:]]*"[^"]+"' "${file}" 2>/dev/null | head -n 1 | sed -E 's/.*"NodeCode"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
    val="$(echo "${val}" | tr -d '[:space:]')"
    if [[ -n "${val}" && "${val^^}" != "N-1" && "${val^^}" != "YOUR_NODE_CODE" && "${val^^}" != "NODE-PLACEHOLDER" && "${val^^}" != "${HOST_SHORT^^}" ]]; then
        # Reject old 14-char XXXX-XXXX-XXXX codes or 3-part codes missing a digit in any part
        if [[ "${val}" =~ ^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4,5}$ ]]; then
            if [[ "${#val}" -ne 15 ]]; then
                return 1
            fi
            local p1="${val:0:4}"
            local p2="${val:5:4}"
            local p3="${val:10:5}"
            if [[ ! "${p1}" =~ [0-9] || ! "${p2}" =~ [0-9] || ! "${p3}" =~ [0-9] ]]; then
                return 1
            fi
        fi
        echo "${val}"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Helper: Compute Deterministic Node Footprint (ARK-FP-* & hw_*)
# ------------------------------------------------------------------------------
NODE_FOOTPRINT_COMBINED=""
NODE_HARDWARE_SUMMARY=""

compute_node_footprint() {
    local os_desc="${1:-Linux}"
    local total_ram_mb="${2:-0}"
    local disk_count="${3:-0}"

    local host_raw
    host_raw="$(hostname 2>/dev/null || echo "${HOST_SHORT}")"
    local host_upper="${host_raw^^}"
    local logical_threads
    logical_threads="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)"
    local os_arch="X64"

    # Extract CPU model name and physical core count from /proc/cpuinfo / lscpu
    local cpu_model="x64 Processor"
    if [[ -f /proc/cpuinfo ]]; then
        local detected_model
        detected_model="$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/  */ /g' || true)"
        if [[ -n "${detected_model}" ]]; then
            cpu_model="${detected_model}"
        fi
    fi

    local phys_cores="${logical_threads}"
    if command -v lscpu >/dev/null 2>&1; then
        local cores_per_socket sockets
        cores_per_socket="$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket:/ {gsub(/[[:space:]]/, "", $2); print $2}' || true)"
        sockets="$(lscpu 2>/dev/null | awk -F: '/^Socket\(s\):/ {gsub(/[[:space:]]/, "", $2); print $2}' || true)"
        if [[ "${cores_per_socket}" =~ ^[0-9]+$ && "${sockets}" =~ ^[0-9]+$ && "${cores_per_socket}" -gt 0 && "${sockets}" -gt 0 ]]; then
            phys_cores=$(( cores_per_socket * sockets ))
        fi
    elif [[ -f /proc/cpuinfo ]]; then
        local cpu_cores_first
        cpu_cores_first="$(awk -F: '/^cpu cores/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
        if [[ "${cpu_cores_first}" =~ ^[0-9]+$ && "${cpu_cores_first}" -gt 0 ]]; then
            phys_cores="${cpu_cores_first}"
        fi
    fi

    local total_ram_gb=$(( (total_ram_mb + 512) / 1024 ))
    if [[ "${total_ram_gb}" -lt 1 ]]; then total_ram_gb=1; fi

    local mounted_vols=1
    if command -v df >/dev/null 2>&1; then
        mounted_vols="$(df -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR>1 && $1 ~ /^\// {count++} END {print count+0}' || echo 1)"
    fi

    # 1. Abodi Enrollment Hardware Fingerprint (hw_<24-hex>)
    local raw_enroll="${host_raw}|${os_desc}|${os_arch}|${logical_threads}"
    local enroll_hex=""
    if command -v sha256sum >/dev/null 2>&1; then
        enroll_hex="$(printf "%s" "${raw_enroll}" | sha256sum | awk '{print substr($1,1,24)}')"
    elif command -v openssl >/dev/null 2>&1; then
        enroll_hex="$(printf "%s" "${raw_enroll}" | openssl dgst -sha256 | awk '{print substr($NF,1,24)}')"
    else
        enroll_hex="000000000000000000000000"
    fi
    local abodi_hw_fp="hw_${enroll_hex,,}"

    # 2. Machine ID & Primary Physical MAC (matches ClusterHardwareProfiler)
    local machine_id="${host_raw}-AARKAM-HOST"
    if [[ -f /etc/machine-id ]]; then
        machine_id="$(tr -d '[:space:]' < /etc/machine-id)"
    elif [[ -f /var/lib/dbus/machine-id ]]; then
        machine_id="$(tr -d '[:space:]' < /var/lib/dbus/machine-id)"
    elif [[ -f /sys/class/dmi/id/product_uuid ]]; then
        machine_id="$(tr -d '[:space:]' < /sys/class/dmi/id/product_uuid)"
    fi

    local primary_mac="00155D000001"
    for net_dev in /sys/class/net/*; do
        local dev_name
        dev_name="$(basename "${net_dev}")"
        if [[ "${dev_name}" == "lo" || "${dev_name}" == tun* || "${dev_name}" == tap* ]]; then
            continue
        fi
        local operstate
        operstate="$(cat "${net_dev}/operstate" 2>/dev/null || echo "down")"
        if [[ "${operstate}" == "up" || "${operstate}" == "unknown" ]]; then
            local raw_mac
            raw_mac="$(tr -d ':\n\r ' < "${net_dev}/address" 2>/dev/null | tr '[:lower:]' '[:upper:]' || true)"
            if [[ -n "${raw_mac}" && "${raw_mac}" != "000000000000" ]]; then
                primary_mac="${raw_mac}"
                break
            fi
        fi
    done

    # 3. Sovereign Hardware Footprint (ARK-FP-XXXXXXXX-XXXXXXXX-XXXXXXXX)
    local profile_payload="${host_upper}|${logical_threads}|${os_arch}|${machine_id}|${primary_mac}"
    local ark_hex=""
    if command -v openssl >/dev/null 2>&1; then
        ark_hex="$(printf "%s" "${profile_payload}" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:${AARKAM_ROOT_PUBKEY_HEX}" 2>/dev/null | awk '{print toupper($NF)}' || true)"
    fi
    if [[ -z "${ark_hex}" || "${#ark_hex}" -lt 24 ]]; then
        ark_hex="$(printf "%s" "${profile_payload}" | sha256sum | awk '{print toupper($1)}')"
    fi
    local ark_fp="ARK-FP-${ark_hex:0:8}-${ark_hex:8:8}-${ark_hex:16:8}"

    local cpu_topology="${phys_cores} Cores, ${os_arch}"
    if [[ "${phys_cores}" != "${logical_threads}" ]]; then
        cpu_topology="${phys_cores} Cores / ${logical_threads} Logical Threads, ${os_arch}"
    fi

    local disk_topology="${disk_count} Physical Disk(s)"
    if [[ "${mounted_vols}" -gt 0 && "${mounted_vols}" != "${disk_count}" ]]; then
        disk_topology="${disk_count} Physical Disk(s) (${mounted_vols} Mounted Volumes)"
    fi

    NODE_FOOTPRINT_COMBINED="${ark_fp} (${abodi_hw_fp})"
    NODE_HARDWARE_SUMMARY="${cpu_model} (${cpu_topology}) | ${total_ram_mb} MB (${total_ram_gb} GB) RAM | ${disk_topology} | MAC: ${primary_mac}"
}

usage() {
    cat <<EOF
Usage: sudo ./install-abodi.sh [OPTIONS]

Automated production installer for the Rokka Abodi Storage & Diagnostics Node Agent (v${ABODI_RELEASE_VERSION}-GA).
Registers the systemd service as '${SERVICE_NAME}'.

Options:
  --node-code <id>           Unique node identifier (if omitted: checks appsettings.json or generates XXXX-XXXX-XXXX)
  --rokka-url <url>          Rokka Coordinator endpoint (default: ${ROKKA_URL})
  --trust-domain <domain>    Zero-Trust SPIFFE trust domain (default: ${TRUST_DOMAIN})
  --enrollment-token <tok>   Single-use Rokka bootstrap token (ET1.<hex>) for initial mTLS CSR enrollment
  --token-file <path>        Path to file containing the single-use enrollment token (scrubbed after bootstrap)
  --api-key <key>            Optional static or cluster-signed (AK1.*) node authentication key
  --master-key-file <path>   Optional path to restricted 256-bit Kdouja cluster master key file
  --source <path>            Path to pre-published Abodi binaries, release .zip archive, or repository root
  --install-dir <path>       Target installation directory (default: ${INSTALL_DIR})
  --storage-dir <path>       Primary storage mount directory (default: ${STORAGE_DIR})
  --storage-mode <mode>      Kdouja SAT execution mode: Embedded (default) or Standalone (kdoujad sidecar)
  --kdouja-mode <mode>       Alias for --storage-mode (Embedded | Standalone)
  --kdouja-endpoint <url>    Standalone kdoujad gRPC endpoint (default: ${KDOUJA_ENDPOINT})
  --allow-os-partition       Permit storage allocation on the OS root partition (evaluation/dev only)
  --disable-direct-io        Disable O_DIRECT unbuffered I/O (for virtualized/tmpfs filesystems)
  --run-as-root              Run systemd service as root instead of dedicated '${SERVICE_USER}' account
  --skip-sysctl              Skip Linux kernel and NVMe I/O scheduler tuning
  --skip-firewall            Skip UFW / firewalld port configuration
  --skip-start               Configure and enable systemd unit without starting it immediately
  --offline                  Air-gapped mode: skip apt/dnf/dotnet online downloads if tools/binaries exist
  --check-only               Run pre-flight system requirements, version compatibility & Node Footprint checks only
  -h, --help                 Display this help message
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
        --api-key)            API_KEY="$2"; shift 2 ;;
        --master-key-file)    MASTER_KEY_FILE="$2"; shift 2 ;;
        --source|--source-path) BINARY_SOURCE="$2"; shift 2 ;;
        --install-dir)        INSTALL_DIR="$2"; shift 2 ;;
        --storage-dir)        STORAGE_DIR="$2"; shift 2 ;;
        --storage-mode|--kdouja-mode) STORAGE_MODE="$2"; shift 2 ;;
        --kdouja-endpoint)    KDOUJA_ENDPOINT="$2"; shift 2 ;;
        --allow-os-partition) ALLOW_OS_PARTITION="true"; shift ;;
        --disable-direct-io)  ENABLE_DIRECT_IO="false"; shift ;;
        --run-as-root)        RUN_AS_ROOT="true"; shift ;;
        --skip-sysctl)        SKIP_SYSCTL="true"; shift ;;
        --skip-firewall)      SKIP_FIREWALL="true"; shift ;;
        --skip-start)         SKIP_START="true"; shift ;;
        --start-service|--start-services) SKIP_START="false"; shift ;;
        --offline)            OFFLINE_MODE="true"; shift ;;
        --check-only)         CHECK_ONLY="true"; shift ;;
        -h|--help)            usage ;;
        *)                    log_error "Unknown option: $1"; usage ;;
    esac
done

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${CYAN} Aarkam Abodi Sovereign Storage & Diagnostics Node Daemon — Linux Installer   ${NC}"
echo -e "${BLUE} Release Version: v${ABODI_RELEASE_VERSION}-GA (V-${ABODI_RELEASE_VERSION}) | Service: ${SERVICE_NAME} (.NET 10.0 x64) ${NC}"
echo -e "${BLUE}==============================================================================${NC}"

# Normalize StorageMode
case "${STORAGE_MODE,,}" in
    embedded)   STORAGE_MODE="Embedded" ;;
    standalone) STORAGE_MODE="Standalone" ;;
    *)
        log_error "Invalid --storage-mode '${STORAGE_MODE}'. Expected 'Embedded' or 'Standalone'."
        exit 1
        ;;
esac

if [[ "$ROKKA_URL" != http://* && "$ROKKA_URL" != https://* ]]; then
    ROKKA_URL="https://${ROKKA_URL}"
fi

# ------------------------------------------------------------------------------
# Step 0: Locate Release Payload & Resolve NodeCode (CLI -> appsettings.json -> Random 14-Char)
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_ZIP_DIR=""
RESOLVED_SOURCE_DIR=""
RESOLVED_CSPROJ=""
IS_SELF_CONTAINED="false"

cleanup_temp() {
    if [[ -n "${TEMP_ZIP_DIR}" && -d "${TEMP_ZIP_DIR}" ]]; then
        rm -rf "${TEMP_ZIP_DIR}"
    fi
}
trap cleanup_temp EXIT

CANDIDATE_SOURCES=(
    "${BINARY_SOURCE}"
    "$(pwd)"
    "${SCRIPT_DIR}"
    "${SCRIPT_DIR}/linux"
    "${SCRIPT_DIR}/V-${ABODI_RELEASE_VERSION}/linux"
    "${SCRIPT_DIR}/V-${ABODI_RELEASE_VERSION}/abodi-v${ABODI_RELEASE_VERSION}-linux-x64.zip"
    "${SCRIPT_DIR}/abodi-v${ABODI_RELEASE_VERSION}-linux-x64.zip"
    "${SCRIPT_DIR}/../dist/bundles/abodi-v${ABODI_RELEASE_VERSION}-linux-x64.zip"
    "${SCRIPT_DIR}/../dist/linux"
    "${SCRIPT_DIR}/.."
)

for cand in "${CANDIDATE_SOURCES[@]}"; do
    if [[ -z "${cand}" || ! -e "${cand}" ]]; then continue; fi

    if [[ -f "${cand}" && "${cand}" == *.zip ]]; then
        if [[ "${CHECK_ONLY}" == "false" ]]; then
            log_info "Extracting release bundle '${cand}'..."
            TEMP_ZIP_DIR="$(mktemp -d /tmp/abodi_inst_XXXXXX)"
            unzip -q "${cand}" -d "${TEMP_ZIP_DIR}"
            cand="${TEMP_ZIP_DIR}"
        else
            log_ok "Located release archive: ${cand}"
            IS_SELF_CONTAINED="true"
            break
        fi
    fi

    if [[ -d "${cand}" ]]; then
        if [[ -f "${cand}/Abodi" ]]; then
            RESOLVED_SOURCE_DIR="$(cd "${cand}" && pwd)"
            if [[ ! -f "${cand}/Abodi.dll" ]]; then
                IS_SELF_CONTAINED="true"
            fi
            log_ok "Located Abodi Linux native executable: ${RESOLVED_SOURCE_DIR}/Abodi (SelfContainedSingleFile=${IS_SELF_CONTAINED})"
            break
        elif [[ -f "${cand}/Abodi.dll" ]]; then
            RESOLVED_SOURCE_DIR="$(cd "${cand}" && pwd)"
            IS_SELF_CONTAINED="false"
            log_ok "Located framework-dependent Abodi assembly: ${RESOLVED_SOURCE_DIR}/Abodi.dll"
            break
        elif [[ -f "${cand}/src/Abodi/Abodi.csproj" ]]; then
            RESOLVED_CSPROJ="$(cd "${cand}" && pwd)/src/Abodi/Abodi.csproj"
            log_ok "Located Abodi source project: ${RESOLVED_CSPROJ}"
            break
        fi
    fi
done

if [[ -n "${NODE_CODE}" ]]; then
    NODE_CODE_SOURCE="CLI Parameter (--node-code)"
else
    APPSETTINGS_CANDIDATES=(
        "$(pwd)/appsettings.json"
        "${SCRIPT_DIR}/appsettings.json"
        "${INSTALL_DIR}/appsettings.json"
        "${CONFIG_DIR}/appsettings.Production.json"
        "${INSTALL_DIR}/appsettings.Production.json"
    )
    if [[ -n "${RESOLVED_SOURCE_DIR}" ]]; then
        APPSETTINGS_CANDIDATES+=("${RESOLVED_SOURCE_DIR}/appsettings.json" "${RESOLVED_SOURCE_DIR}/appsettings.Production.json")
    fi

    for cfg_file in "${APPSETTINGS_CANDIDATES[@]}"; do
        if found_code="$(extract_node_code_from_file "${cfg_file}")"; then
            NODE_CODE="${found_code}"
            NODE_CODE_SOURCE="Loaded from ${cfg_file}"
            log_ok "Resolved existing NodeCode '${NODE_CODE}' from '${cfg_file}'."
            break
        fi
    done

    if [[ -z "${NODE_CODE}" ]]; then
        NODE_CODE="$(generate_random_node_code)"
        NODE_CODE_SOURCE="Auto-Generated (XXXX-XXXX-XXXXX, 15 chars)"
        log_info "Generated random NodeCode: ${NODE_CODE} (15 chars [4-4-5], each part with >=1 digit)"
    fi
fi

log_info "Validating Aarkam V2 Ecosystem Version Compatibility Matrix:"
echo "  • Aarkam Abodi Node Daemon   : v${ABODI_RELEASE_VERSION}-GA (V-${ABODI_RELEASE_VERSION}) | Service: ${SERVICE_NAME}"
echo "  • Aarkam Rokka Coordinator   : >= v${REQUIRED_ROKKA_MIN_VERSION} (Rokka.Contracts ${REQUIRED_ROKKA_MIN_VERSION}, mTLS :57774)"
echo "  • Aarkam Kdouja SAT Daemon   : v${REQUIRED_KDOUJA_SAT_VERSION} (kdoujad :57771) | Mode: ${STORAGE_MODE}"
echo "  • Aarkam.Kdouja.SDK Suite    : v${REQUIRED_KDOUJA_SDK_VERSION} (Primitives v${REQUIRED_KDOUJA_PRIM_VERSION}, Engine v2.0.0)"
echo "  • Aarkam AM Fleet CLI        : >= v${REQUIRED_AM_CLI_MIN_VERSION}"
echo "  • Zero-Trust SPIFFE Domain   : spiffe://${TRUST_DOMAIN}/node/${NODE_CODE}"
log_ok "Target Rokka Coordinator endpoint: ${ROKKA_URL}"

# ------------------------------------------------------------------------------
# Step 1: Root, Architecture, Kernel, glibc, OS & Node Footprint Pre-Flight Checks
# ------------------------------------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        log_warn "Running in --check-only mode as non-root user (EUID=${EUID}). Production install requires sudo/root."
    else
        log_error "This installer must be executed with root privileges (use sudo)."
        exit 1
    fi
else
    log_ok "Root privilege check passed."
fi

ARCH="$(uname -m)"
if [[ "${ARCH}" != "x86_64" && "${ARCH}" != "amd64" ]]; then
    log_error "Unsupported CPU architecture '${ARCH}'. Abodi v${ABODI_RELEASE_VERSION} requires 64-bit x86_64 (amd64)."
    exit 1
fi
log_ok "CPU architecture check passed (${ARCH})."

if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect Linux distribution (/etc/os-release is missing)."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
OS_ID="${ID:-unknown}"
OS_VERSION="${VERSION_ID:-unknown}"
KERNEL_REL="$(uname -r)"

log_info "Detected OS: ${PRETTY_NAME:-$OS_ID} | Kernel: ${KERNEL_REL} | Arch: ${ARCH}"

KERNEL_MAJOR="$(echo "${KERNEL_REL}" | cut -d. -f1)"
KERNEL_MINOR="$(echo "${KERNEL_REL}" | cut -d. -f2 | sed 's/[^0-9].*//')"
if (( KERNEL_MAJOR < 5 || (KERNEL_MAJOR == 5 && ${KERNEL_MINOR:-0} < 15) )); then
    log_warn "Linux kernel ${KERNEL_REL} is older than recommended 5.15+ baseline for NVMe Direct I/O."
else
    log_ok "Linux kernel version check passed (${KERNEL_REL})."
fi

if command -v ldd >/dev/null 2>&1; then
    GLIBC_VER="$(ldd --version 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+$' || true)"
    if [[ -n "${GLIBC_VER}" ]]; then
        log_ok "Detected glibc version: ${GLIBC_VER} (>= 2.34 recommended)."
    fi
fi

TOTAL_MEM_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
TOTAL_MEM_MB="$((TOTAL_MEM_KB / 1024))"
if (( TOTAL_MEM_MB < 1800 )); then
    log_warn "Host has ${TOTAL_MEM_MB} MB RAM. Minimum required for Abodi is 2,048 MB (8,192 MB+ recommended for production)."
else
    log_ok "Memory check passed: ${TOTAL_MEM_MB} MB RAM available."
fi

DISK_COUNT="$(lsblk -dn -o TYPE 2>/dev/null | grep -c '^disk$' || echo 1)"
compute_node_footprint "Linux ${KERNEL_REL}" "${TOTAL_MEM_MB}" "${DISK_COUNT}"
log_ok "Computed Node Footprint: ${NODE_FOOTPRINT_COMBINED}"
log_info "Hardware Resource Footprint: ${NODE_HARDWARE_SUMMARY}"

if command -v timedatectl >/dev/null 2>&1; then
    if timedatectl status 2>/dev/null | grep -qi "System clock synchronized: yes"; then
        log_ok "System clock is NTP synchronized (mTLS clock-skew compliant)."
    else
        log_warn "System clock NTP synchronization not confirmed by timedatectl. Ensure chronyd or systemd-timesyncd is active for mTLS."
    fi
fi

# ------------------------------------------------------------------------------
# Step 2: Verify / Install Hardware Telemetry & System Dependencies
# ------------------------------------------------------------------------------
REQUIRED_CMDS=(lsblk smartctl nvme setcap curl)

install_debian_ubuntu_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq || log_warn "apt-get update returned non-zero (air-gapped host?); attempting local cache install..."
    apt-get install -y -qq \
        curl wget ca-certificates gnupg lsb-release apt-transport-https unzip \
        smartmontools nvme-cli util-linux pciutils dmidecode lm-sensors \
        iproute2 ethtool libsqlite3-0 libicu-dev libssl3 acl libcap2-bin
}

install_rhel_deps() {
    dnf install -y -q \
        curl wget ca-certificates gnupg2 unzip \
        smartmontools nvme-cli util-linux pciutils dmidecode lm_sensors \
        iproute ethtool sqlite-libs libicu openssl-libs acl libcap
}

if [[ "${CHECK_ONLY}" == "false" && "${OFFLINE_MODE}" == "false" ]]; then
    log_info "Ensuring hardware telemetry & storage prerequisite packages are installed..."
    case "${OS_ID}" in
        ubuntu|debian)
            install_debian_ubuntu_deps || log_warn "Package installation encountered warnings; verifying required binaries..."
            ;;
        rhel|rocky|almalinux|centos|fedora)
            install_rhel_deps || log_warn "Package installation encountered warnings; verifying required binaries..."
            ;;
        *)
            log_warn "Unrecognized distribution '${OS_ID}'. Skipping package manager invocation and verifying required binaries..."
            ;;
    esac
fi

for cmd in "${REQUIRED_CMDS[@]}"; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        log_ok "Verified required utility: $(command -v "${cmd}")"
    else
        if [[ "${CHECK_ONLY}" == "true" ]]; then
            log_warn "Missing required utility '${cmd}' (will be installed during full execution)."
        else
            log_error "Required utility '${cmd}' is missing. Install smartmontools, nvme-cli, util-linux, libcap2-bin/libcap, and curl."
            exit 1
        fi
    fi
done

# ------------------------------------------------------------------------------
# Step 3: Verify / Install .NET 10.0 ASP.NET Core Runtime (Only if Needed)
# ------------------------------------------------------------------------------
ensure_dotnet_10() {
    if command -v dotnet >/dev/null 2>&1; then
        if dotnet --list-runtimes 2>/dev/null | grep -q "Microsoft.AspNetCore.App 10\."; then
            log_ok ".NET 10.0 ASP.NET Core Runtime detected on host."
            return 0
        fi
    fi

    if [[ "${IS_SELF_CONTAINED}" == "true" ]]; then
        log_ok "Self-contained single-file Abodi binary detected; external .NET 10.0 runtime installation is not required (air-gap ready)."
        return 0
    fi

    if [[ "${CHECK_ONLY}" == "true" || "${OFFLINE_MODE}" == "true" ]]; then
        log_warn ".NET 10.0 ASP.NET Core Runtime is not installed and no self-contained binary was detected."
        return 0
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

ensure_dotnet_10

if [[ "${STORAGE_MODE}" == "Standalone" ]]; then
    log_info "Verifying Standalone Kdouja SAT (v${REQUIRED_KDOUJA_SAT_VERSION}) prerequisite at '${KDOUJA_ENDPOINT}'..."
    if command -v kdoujad >/dev/null 2>&1; then
        log_ok "Detected installed kdoujad binary: $(command -v kdoujad)"
    elif [[ -x "/opt/kdouja/kdoujad" ]]; then
        log_ok "Detected installed kdoujad binary at /opt/kdouja/kdoujad"
    else
        log_warn "kdoujad binary not found in PATH or /opt/kdouja. Ensure Aarkam Kdouja SAT v${REQUIRED_KDOUJA_SAT_VERSION} is running at ${KDOUJA_ENDPOINT}."
    fi
fi

OUTBOX_CHECK_PATH="${OUTBOX_DIR}"
while [[ ! -d "${OUTBOX_CHECK_PATH}" && "${OUTBOX_CHECK_PATH}" != "/" ]]; do
    OUTBOX_CHECK_PATH="$(dirname "${OUTBOX_CHECK_PATH}")"
done
FREE_KB="$(df -Pk "${OUTBOX_CHECK_PATH}" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)"
FREE_GB="$((FREE_KB / 1024 / 1024))"
if (( FREE_KB < 10485760 )); then
    log_warn "Outbox filesystem (${OUTBOX_CHECK_PATH}) has ~${FREE_GB} GB free. Abodi TelemetryOutbox enforces a 10 GB minimum free space guard."
else
    log_ok "Outbox filesystem (${OUTBOX_CHECK_PATH}) free space check passed (${FREE_GB} GB available)."
fi

KDOUJA_BASE_DIR="${STORAGE_DIR}/kdouja"

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN} Rokka Abodi Node Agent (v${ABODI_RELEASE_VERSION}-GA) Pre-Flight Check Complete (Linux x86_64)${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo "  Service Name:         ${SERVICE_NAME}"
    echo "  Node Code:            ${NODE_CODE} (${NODE_CODE_SOURCE})"
    echo "  Node Footprint:       ${NODE_FOOTPRINT_COMBINED}"
    echo "  Hardware Footprint:   ${NODE_HARDWARE_SUMMARY}"
    echo "  Rokka Coordinator:    ${ROKKA_URL}"
    echo "  SPIFFE Trust Domain:  ${TRUST_DOMAIN} (spiffe://${TRUST_DOMAIN}/node/${NODE_CODE})"
    echo "  Kdouja Storage Mode:  ${STORAGE_MODE} ($(if [[ "${STORAGE_MODE}" == "Standalone" ]]; then echo "${KDOUJA_ENDPOINT}"; else echo "${KDOUJA_BASE_DIR}"; fi))"
    echo "  Binary Directory:     ${INSTALL_DIR}"
    echo "  Storage Directory:    ${STORAGE_DIR}"
    echo -e "${GREEN}==============================================================================${NC}"
    exit 0
fi

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
        --comment "Aarkam Abodi Storage & Diagnostics Daemon" \
        "${SERVICE_USER}"
    log_ok "Created system user '${SERVICE_USER}'."
fi

if getent group disk >/dev/null 2>&1; then
    usermod -aG disk "${SERVICE_USER}"
fi

mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${SECURITY_DIR}" "${OUTBOX_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"

chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"
chmod 0750 "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${OUTBOX_DIR}" "${STORAGE_DIR}" "${LOG_DIR}"
chmod 0700 "${SECURITY_DIR}"

SMARTCTL_BIN="$(command -v smartctl || true)"
if [[ -n "${SMARTCTL_BIN}" ]]; then
    setcap 'cap_sys_rawio,cap_sys_admin+ep' "${SMARTCTL_BIN}" || log_warn "Could not set capabilities on ${SMARTCTL_BIN}"
    log_ok "Granted cap_sys_rawio,cap_sys_admin to ${SMARTCTL_BIN}"
fi

# ------------------------------------------------------------------------------
# Step 5: Stop Services/Processes & Deploy Abodi Application Binaries
# ------------------------------------------------------------------------------
# Migrate/stop legacy rokka-abodi unit if present
if systemctl is-active --quiet "${LEGACY_SERVICE_NAME}.service" 2>/dev/null; then
    log_info "Stopping legacy ${LEGACY_SERVICE_NAME}.service..."
    systemctl stop "${LEGACY_SERVICE_NAME}.service" || true
fi
if [[ -f "/etc/systemd/system/${LEGACY_SERVICE_NAME}.service" && ! -L "/etc/systemd/system/${LEGACY_SERVICE_NAME}.service" ]]; then
    systemctl disable "${LEGACY_SERVICE_NAME}.service" 2>/dev/null || true
    rm -f "/etc/systemd/system/${LEGACY_SERVICE_NAME}.service"
fi

if systemctl is-active --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
    log_info "Stopping running ${SERVICE_NAME}.service before updating binaries..."
    systemctl stop "${SERVICE_NAME}.service" || true
fi

# Force-terminate any lingering Abodi process holding a lock on the binary
if pgrep -x "Abodi" >/dev/null 2>&1; then
    log_info "Force-terminating lingering Abodi process(es)..."
    pkill -9 -x "Abodi" 2>/dev/null || true
    sleep 1
fi

deploy_binaries() {
    local target_real
    target_real="$(cd "${INSTALL_DIR}" && pwd)"

    if [[ -n "${RESOLVED_SOURCE_DIR}" ]]; then
        local src_real
        src_real="$(cd "${RESOLVED_SOURCE_DIR}" && pwd)"
        if [[ "${src_real}" != "${target_real}" ]]; then
            log_info "Deploying Abodi v${ABODI_RELEASE_VERSION} binaries from '${src_real}' to '${INSTALL_DIR}'..."
            cp -a "${src_real}/." "${INSTALL_DIR}/"
            rm -rf "${INSTALL_DIR}/logs" "${INSTALL_DIR}"/*.db "${INSTALL_DIR}"/*.db-shm "${INSTALL_DIR}"/*.db-wal 2>/dev/null || true
            log_ok "Deployed Abodi binaries to '${INSTALL_DIR}'."
        else
            log_ok "Abodi binaries are already staged in '${INSTALL_DIR}'."
        fi
    elif [[ -n "${RESOLVED_CSPROJ}" ]]; then
        log_info "Publishing Abodi single-file executable from '${RESOLVED_CSPROJ}'..."
        dotnet publish "${RESOLVED_CSPROJ}" \
            -f net10.0 -c Release -r linux-x64 --self-contained true \
            /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true \
            /p:EnableCompressionInSingleFile=true /p:Version="${ABODI_RELEASE_VERSION}" \
            -o "${INSTALL_DIR}"
        log_ok "Published Abodi to '${INSTALL_DIR}'."
    elif [[ -f "${INSTALL_DIR}/Abodi" || -f "${INSTALL_DIR}/Abodi.dll" ]]; then
        log_ok "Existing Abodi binaries detected in '${INSTALL_DIR}'."
    else
        log_warn "No local binaries or source tree found. Ensure Abodi binary is placed in ${INSTALL_DIR} before starting the service."
    fi

    if [[ -f "${INSTALL_DIR}/Abodi" ]]; then
        chmod 0750 "${INSTALL_DIR}/Abodi"
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
    if command -v shred >/dev/null 2>&1; then
        shred -u "${ENROLLMENT_TOKEN_FILE}" 2>/dev/null || rm -f "${ENROLLMENT_TOKEN_FILE}"
    else
        dd if=/dev/zero of="${ENROLLMENT_TOKEN_FILE}" bs=64 count=1 status=none 2>/dev/null || true
        rm -f "${ENROLLMENT_TOKEN_FILE}"
    fi
    log_ok "Read and scrubbed external token file '${ENROLLMENT_TOKEN_FILE}'."
fi

if [[ -n "${ENROLLMENT_TOKEN}" ]]; then
    umask 0077
    printf "%s" "${ENROLLMENT_TOKEN}" > "${BOOTSTRAP_TOKEN_PATH}"
    chown "${SERVICE_USER}:${SERVICE_GROUP}" "${BOOTSTRAP_TOKEN_PATH}"
    chmod 0600 "${BOOTSTRAP_TOKEN_PATH}"
    unset ENROLLMENT_TOKEN
    log_ok "Provisioned single-use enrollment token at ${BOOTSTRAP_TOKEN_PATH} (mode 0600; auto-scrubbed on first boot)."
fi

# ------------------------------------------------------------------------------
# Step 7: Persist NodeCode to appsettings.json & Generate appsettings.Production.json
# ------------------------------------------------------------------------------
if [[ -f "${INSTALL_DIR}/appsettings.json" ]]; then
    sed -i -E "s/(\"NodeCode\"[[:space:]]*:[[:space:]]*\")[^\"]+(\")/\1${NODE_CODE}\2/" "${INSTALL_DIR}/appsettings.json" 2>/dev/null || true
fi

log_info "Generating production configuration in ${CONFIG_DIR}/appsettings.Production.json (NodeCode=${NODE_CODE}, Kdouja:Mode=${STORAGE_MODE})..."

EXTRA_AGENT_FIELDS=""
if [[ -n "${API_KEY}" ]]; then
    EXTRA_AGENT_FIELDS="${EXTRA_AGENT_FIELDS},"$'\n'"    \"ApiKey\": \"${API_KEY}\""
fi
if [[ -n "${MASTER_KEY_FILE}" ]]; then
    EXTRA_AGENT_FIELDS="${EXTRA_AGENT_FIELDS},"$'\n'"    \"MasterKeyFile\": \"${MASTER_KEY_FILE}\""
fi

cat > "${CONFIG_DIR}/appsettings.Production.json" <<EOF
{
  "SerilogConfig": {
    "MinimumLevel": "Information",
    "WriteToConsole": true,
    "WriteToFile": true,
    "LogDirectory": "${LOG_DIR}",
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
    "LocalStorageGrpcUrl": "http://127.0.0.1:7775",
    "TelemetryIntervalSeconds": 10,
    "HeartbeatIntervalSeconds": 15,
    "ManifestCacheHours": 6${EXTRA_AGENT_FIELDS}
  },
  "Cluster": {
    "TrustDomain": "${TRUST_DOMAIN}"
  },
  "Security": {
    "TrustDomain": "${TRUST_DOMAIN}",
    "IdentityStorageDirectory": "${SECURITY_DIR}",
    "EnrollmentTokenFile": "${BOOTSTRAP_TOKEN_PATH}",
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
  "Kdouja": {
    "Mode": "${STORAGE_MODE}",
    "Embedded": {
      "BaseDirectory": "${KDOUJA_BASE_DIR}",
      "EnableDirectIO": ${ENABLE_DIRECT_IO},
      "PageSizeBytes": 4096,
      "EnableWalFsync": true
    },
    "Standalone": {
      "Endpoint": "${KDOUJA_ENDPOINT}",
      "EnableRetry": true
    }
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
log_ok "Generated ${CONFIG_DIR}/appsettings.Production.json"

# ------------------------------------------------------------------------------
# Step 8: Apply Linux Kernel & NVMe I/O Scheduler Tuning
# ------------------------------------------------------------------------------
if [[ "${SKIP_SYSCTL}" == "false" ]]; then
    log_info "Applying production Linux kernel & storage sysctl tuning..."
    cat > /etc/sysctl.d/99-rokka-abodi.conf <<EOF
# Aarkam Abodi Storage & Telemetry Node Kernel Tuning
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

    for sched in /sys/block/nvme*/queue/scheduler; do
        if [[ -w "${sched}" ]]; then
            echo none > "${sched}" 2>/dev/null || true
        fi
    done
    log_ok "Applied sysctl parameters and NVMe queue scheduler optimizations."
fi

# ------------------------------------------------------------------------------
# Step 9: Configure systemd Service Unit ('Aarkam.Abodi.service')
# ------------------------------------------------------------------------------
log_info "Creating hardened systemd unit /etc/systemd/system/${SERVICE_NAME}.service..."

SVC_USER="${SERVICE_USER}"
SVC_GROUP="${SERVICE_GROUP}"
if [[ "${RUN_AS_ROOT}" == "true" ]]; then
    SVC_USER="root"
    SVC_GROUP="root"
fi

if [[ -x "${INSTALL_DIR}/Abodi" ]]; then
    EXEC_START="${INSTALL_DIR}/Abodi"
elif [[ -f "${INSTALL_DIR}/Abodi.dll" ]]; then
    DOTNET_BIN="$(command -v dotnet || echo /usr/bin/dotnet)"
    EXEC_START="${DOTNET_BIN} ${INSTALL_DIR}/Abodi.dll"
else
    EXEC_START="${INSTALL_DIR}/Abodi"
fi

cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Aarkam Abodi Zero-Trust Storage & Hardware Diagnostics Node Agent (v${ABODI_RELEASE_VERSION})
Documentation=https://aarkam.io/docs/abodi
After=network-online.target local-fs.target
Wants=network-online.target

[Service]
Type=simple
User=${SVC_USER}
Group=${SVC_GROUP}
SupplementaryGroups=disk
WorkingDirectory=${INSTALL_DIR}
ExecStart=${EXEC_START}
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
Environment=DOTNET_CLI_TELEMETRY_OPTOUT=1
Environment=ROKKA_IDENTITY_STORAGE_DIR=${SECURITY_DIR}
Environment=ROKKA_ENROLLMENT_TOKEN_FILE=${BOOTSTRAP_TOKEN_PATH}
Environment=ABODI_ALLOW_OS_PARTITION=${ALLOW_OS_PARTITION}
Environment=Kdouja__Mode=${STORAGE_MODE}
Environment=Kdouja__Embedded__BaseDirectory=${KDOUJA_BASE_DIR}
Environment=Kdouja__Standalone__Endpoint=${KDOUJA_ENDPOINT}

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
Alias=aarkam-abodi.service rokka-abodi.service
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
log_ok "Registered and enabled systemd service '${SERVICE_NAME}.service' (ExecStart=${EXEC_START})."

# ------------------------------------------------------------------------------
# Step 10: Configure Host Firewall (UFW / firewalld)
# ------------------------------------------------------------------------------
if [[ "${SKIP_FIREWALL}" == "false" ]]; then
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        log_info "Configuring UFW firewall rules for Abodi mTLS ports (57775/tcp, 57776/tcp)..."
        ufw allow 57775/tcp comment "Aarkam Abodi gRPC mTLS" >/dev/null
        ufw allow 57776/tcp comment "Aarkam Abodi REST HTTPS" >/dev/null
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
# Step 11: Start Service & Verify Health Probes if Binaries Present
# ------------------------------------------------------------------------------
if [[ "${SKIP_START}" == "true" ]]; then
    log_info "Skipped service startup (--skip-start). Start manually via: sudo systemctl start ${SERVICE_NAME}"
elif [[ -x "${INSTALL_DIR}/Abodi" || -f "${INSTALL_DIR}/Abodi.dll" ]]; then
    log_info "Starting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service"
    sleep 3

    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
        log_ok "${SERVICE_NAME} is active and running."

        if command -v curl >/dev/null 2>&1; then
            if curl -fsS --max-time 5 "http://127.0.0.1:7776/api/v1/health/ping" >/dev/null 2>&1; then
                log_ok "Abodi Liveness Probe (/api/v1/health/ping) succeeded."
            else
                log_warn "Liveness probe on http://127.0.0.1:7776/api/v1/health/ping is still warming up."
            fi

            if curl -fsS --max-time 5 "http://127.0.0.1:7776/healthz/kdouja" >/dev/null 2>&1; then
                log_ok "Kdouja SAT Storage Probe (/healthz/kdouja, Mode=${STORAGE_MODE}) succeeded."
            else
                log_warn "Kdouja health check (/healthz/kdouja) returned warning or is still warming up."
            fi
        fi
    else
        log_error "${SERVICE_NAME} failed to start. Inspect logs via: sudo journalctl -u ${SERVICE_NAME} -n 100 --no-pager"
        exit 1
    fi
else
    log_warn "Abodi binary not yet present in ${INSTALL_DIR}. Service is configured and enabled; start it after copying binaries:"
    log_warn "  sudo systemctl start ${SERVICE_NAME}"
fi

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN} Rokka Abodi Node Agent (v${ABODI_RELEASE_VERSION}-GA) Installation Complete (Linux x86_64)${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo "  Service Name:         ${SERVICE_NAME}"
echo "  Node Code:            ${NODE_CODE} (${NODE_CODE_SOURCE})"
echo "  Node Footprint:       ${NODE_FOOTPRINT_COMBINED}"
echo "  Hardware Footprint:   ${NODE_HARDWARE_SUMMARY}"
echo "  Rokka Coordinator:    ${ROKKA_URL}"
echo "  SPIFFE Trust Domain:  ${TRUST_DOMAIN} (spiffe://${TRUST_DOMAIN}/node/${NODE_CODE})"
echo "  Kdouja Storage Mode:  ${STORAGE_MODE} ($(if [[ "${STORAGE_MODE}" == "Standalone" ]]; then echo "${KDOUJA_ENDPOINT}"; else echo "${KDOUJA_BASE_DIR}"; fi))"
echo "  Binary Directory:     ${INSTALL_DIR}"
echo "  Configuration File:   ${CONFIG_DIR}/appsettings.Production.json"
echo "  Zero-Trust Key Store: ${SECURITY_DIR} (mode 0700)"
echo "  SQLite WAL Outbox:    ${OUTBOX_DIR}/abodi-telemetry.db"
echo "  Storage Directory:    ${STORAGE_DIR}"
echo "  Log Directory:        ${LOG_DIR}"
echo "  Service Status:       sudo systemctl status ${SERVICE_NAME}"
echo "  Live Logs:            sudo journalctl -u ${SERVICE_NAME} -f"
echo "  Liveness Probe:       curl -s http://127.0.0.1:7776/api/v1/health/ping"
echo "  Kdouja Health Probe:  curl -s http://127.0.0.1:7776/healthz/kdouja"
echo -e "${GREEN}==============================================================================${NC}"
