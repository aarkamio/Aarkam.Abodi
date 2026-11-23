# Abodi Sovereign Hardware Diagnostics & Storage Node Agent
# Official Production Release Notes — Version `v1.0.4-GA` (`V-1.0.4`)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | **Aarkam Abodi** — Sovereign Storage & Hardware Diagnostics Node Daemon |
| **Release Version** | **`v1.0.4-GA` (`V-1.0.4`, General Availability)** |
| **Release Date** | November 2026 |
| **Target Runtime** | `.NET 10.0` (Self-Contained Single-File Native Binaries & OCI Container) |
| **Architectural Role** | Rokka-Native Storage Node Gateway, Hardware Telemetry Harvester & Predictive Maintenance Engine |
| **Storage Engine Integration** | Dual-Mode **Kdouja SAT** (`Embedded` In-Process & `Standalone` `kdoujad` Daemon via `Aarkam.Kdouja.SDK v1.0.1`) |
| **Upstream Coordinator** | **Aarkam Rokka** Distributed Storage Coordinator (`v1.0.2+`, gRPC/REST over Zero-Trust mTLS `:57774`) |
| **Compliance & Security** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3, Zero-Trust SPIFFE mTLS (`ECDSA P-256`) |
| **Supported Platforms** | Linux `x86_64` (Ubuntu 22.04/24.04 LTS, Debian 12+, RHEL/Rocky/Alma 9+), Windows Server `x64` (2022/2025), Docker & Kubernetes |

---

## 📖 Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Valid Ecosystem Version Compatibility Matrix](#2-valid-ecosystem-version-compatibility-matrix)
3. [What's New in `v1.0.4-GA` & `v1.0.3-GA`](#3-whats-new-in-v104-ga--v103-ga)
4. [Cumulative Highlights from `v1.0.2-GA` & `v1.0.1-GA`](#4-cumulative-highlights-from-v102-ga--v101-ga)
5. [Deep-Dive: How Abodi Integrates with Rokka & Kdouja SAT](#5-deep-dive-how-abodi-integrates-with-rokka--kdouja-sat)
6. [Distribution Packages & Verified SHA-256 Checksums (`v1.0.4-GA`)](#6-distribution-packages--verified-sha-256-checksums-v104-ga)
7. [Deployment & Upgrade Runbook](#7-deployment--upgrade-runbook)
8. [Network Port & Protocol Matrix](#8-network-port--protocol-matrix)

---

## 1. Executive Summary

**Aarkam Abodi `v1.0.4-GA`** is the production node daemon deployed on every physical and virtual storage host within the **Rokka Distributed Storage Fabric**. Operating with zero dependency on external cloud services or internet connectivity, Abodi bridges physical storage media (**Kdouja SAT** Direct I/O & LSM-Tree engine) with cluster-wide orchestration (**Rokka Coordinator**).

Release **`v1.0.4-GA`** standardizes the **`Aarkam.Abodi`** service identity across Windows and Linux, introduces automated **15-character `NodeCode` (`XXXX-XXXX-XXXXX`)** provisioning, prints deterministic **Sovereign Cryptographic Node Footprints (`ARK-FP-*` & `hw_*`)** alongside real physical hardware topology (CPU model, physical cores vs. logical threads, Win32 `GlobalMemoryStatusEx` physical RAM, and physical disks vs. mounted volumes), and provides zero-lock in-place Windows binary upgrades on top of the **Dual-Mode Kdouja SAT Integration (`Aarkam.Kdouja.SDK v1.0.1`)**.

---

## 2. Valid Ecosystem Version Compatibility Matrix

Always deploy matching, validated versions across the Aarkam V2 Sovereign Storage stack:

| Component / Package | Valid Version | Image / Package Identifier | Architectural Role |
| :--- | :---: | :--- | :--- |
| **Aarkam Abodi Daemon** | **`v1.0.4` (`V-1.0.4`)** | `aarkam/aarkam.abodi:v1.0.4` | Node Diagnostics, Telemetry, Zero-Trust mTLS Gateway & Placement Agent |
| **Aarkam Kdouja SAT Daemon** | **`v1.0.2`** | `aarkam/aarkam.kdouja:v1.0.2` | Standalone LSM-Tree & Direct I/O Block Storage Daemon (`kdoujad` on `:57771`) |
| **`Aarkam.Kdouja.SDK`** | **`1.0.1`** | NuGet: `Aarkam.Kdouja.SDK` | Unified .NET 8/10 SDK abstracting Embedded & Standalone Kdouja modes |
| **`Aarkam.Kdouja.SDK.Embedded`** | **`1.0.1`** | NuGet: `Aarkam.Kdouja.SDK.Embedded` | In-process Kdouja engine provider for Abodi & Rokka |
| **`Aarkam.Kdouja.SDK.Remote`** | **`1.0.1`** | NuGet: `Aarkam.Kdouja.SDK.Remote` | Standalone gRPC client provider for `kdoujad`, Rokka & Abodi |
| **`Aarkam.Kdouja.SDK.AspNetCore`** | **`1.0.1`** | NuGet: `Aarkam.Kdouja.SDK.AspNetCore` | ASP.NET Core `IHealthCheck` integration (`/healthz/kdouja`) |
| **`Aarkam.Kdouja.Primitives`** | **`1.0.6`** | NuGet: `Aarkam.Kdouja.Primitives` | Low-level zero-allocation buffers, CRC32 checksums, and Direct I/O primitives |
| **Aarkam Rokka Coordinator** | **`v1.0.2+` (`v2.1`)** | `Rokka.Common` / `Rokka.Contracts` / `Rokka.Client` `1.0.2` | Distributed Consensus Coordinator, Node CA (`EnrollNode`), Placement & Erasure Coding |
| **Aarkam Ahmodi Core** | **`1.0.1`** | NuGet: `Aarkam.Ahmodi` / `Aarkam.Ahmodi.Abstractions` | Shared core contracts and primitives used by Rokka |

---

## 3. What's New in `v1.0.4-GA` & `v1.0.3-GA`

### 3.1 Migration to Official `Aarkam.Kdouja.SDK` (`v1.0.1`) NuGet Packages
- Replaced legacy local project references in `src/Abodi/Abodi.csproj` with the published NuGet suite:
  - `Aarkam.Kdouja.SDK` (`1.0.1`)
  - `Aarkam.Kdouja.SDK.Embedded` (`1.0.1`)
  - `Aarkam.Kdouja.SDK.Remote` (`1.0.1`)
  - `Aarkam.Kdouja.SDK.AspNetCore` (`1.0.1`)
  - `Aarkam.Kdouja.Primitives` (`1.0.6`)
- **Self-Contained CI & Container Builds:** Decoupling `Abodi.csproj` from relative `..\..\..\Aarkam.Kdouja` source paths allows standalone `dotnet publish` and containerized `Dockerfile` builds to restore Kdouja dependencies directly from NuGet.

### 3.2 Dual-Mode Storage Engine Registration (`Embedded` vs. `Standalone`)
- **Unified DI Wiring (`ServicesRegistration.cs`):** Configured `services.AddKdouja(builder.Configuration).UseEmbedded().UseStandalone().WithTelemetry()` to dynamically bind `IKdoujaClient` and `IKdoujaStorageClient` based on `Kdouja:Mode` (`Embedded` or `Standalone`) in `appsettings.json` or environment variables (`Kdouja__Mode`).
- **OpenTelemetry Instrumentation (`WithTelemetry()`):** Automatically wraps the active `IKdoujaClient` with `InstrumentedKdoujaClient` to emit OpenTelemetry spans and metrics alongside Abodi's native `Abodi.Agent` OTLP pipeline.
- **Dedicated Kdouja Health Check Endpoint (`/healthz/kdouja`):** Registered `KdoujaHealthCheck` (`Aarkam.Kdouja.SDK.AspNetCore`) and mapped `/healthz/kdouja` in `Program.cs` so container orchestrators and operators can probe the underlying Kdouja storage substrate (whether in-process or remote `kdoujad`) independently of the node liveness probe (`/api/v1/health/ping`).

### 3.3 Docker Compose Standalone `kdoujad` Sidecar Profile
- Updated `docker-compose.yml` to support both deployment topologies from a single compose file:
  - **Default (`Embedded`):** Runs `aarkam/aarkam.abodi:v1.0.4` as a single self-contained container with `Kdouja__Mode=Embedded`.
  - **Standalone Profile (`--profile standalone`):** Launches an isolated `kdoujad` sidecar container (`aarkam/aarkam.kdouja:v1.0.2`) sharing the `abodi_storage` volume and communicating with `abodi` over the internal Compose network (`http://kdoujad:57771`) without exposing port `57771` to external hosts.

### 3.4 Unified `Aarkam.Abodi` Service Identity, 15-Char `NodeCode` & Hardware Footprint Telemetry
- **Standardized `Aarkam.Abodi` Service Name:** Both Windows Service (`ServicesRegistration.cs` / `install-abodi.ps1`) and Linux `systemd` (`Aarkam.Abodi.service` / `install-abodi.sh`) now register under **`Aarkam.Abodi`** and automatically stop/remove legacy `Rokka.Abodi.Agent` or `rokka-abodi` service registrations during upgrade.
- **Deterministic 15-Character `NodeCode` (`XXXX-XXXX-XXXXX`):** Installers inspect `appsettings.json` / `appsettings.Production.json` for an existing `NodeCode`, or auto-generate a cryptographically random 15-character `4-4-5` code (`0-9A-Z`, guaranteed $\ge 1$ digit and $\ge 1$ letter per part) and persist it into `appsettings.json` and `appsettings.Production.json`.
- **Cryptographic Node Footprint & Real Hardware Inventory:** Installers compute and display both the sovereign cryptographic node footprint (`ARK-FP-XXXXXXXX-XXXXXXXX-XXXXXXXX (hw_<24-hex>)`) and true physical hardware specs (CPU model, physical cores vs. logical threads, physical RAM via Win32 `GlobalMemoryStatusEx` / `/proc/meminfo`, and physical disks vs. mounted volumes).
- **Zero-Lock Windows Binary Upgrade:** `install-abodi.ps1` gracefully stops services, force-terminates lingering `Abodi.exe` processes (`Stop-Process` + `taskkill /F /IM Abodi.exe /T`), and applies NTFS atomic rename unlocking before deploying updated single-file binaries.

---

## 4. Cumulative Highlights from `v1.0.2-GA` & `v1.0.1-GA`

### 4.1 Rokka-Only Zero-Trust mTLS Node Identity & Enrollment (`v1.0.2-GA`)
- **Strict Hierarchical Separation:** `Aarkam.IO` and `AM CLI` communicate exclusively with **Rokka Coordinator (`:57774`)**; Abodi enrolls, authenticates, and reports strictly to Rokka.
- **On-Node ECDSA P-256 Key Generation (`NodeIdentityStorage`):** Private keys (`node-identity.key`) are generated locally and persisted in `/var/lib/rokka/security` (Linux mode `0700`/`0600`) or `C:\ProgramData\Rokka\Security` (Windows restricted NTFS ACLs) and never cross the network.
- **Single-Use Opaque Bootstrap Tokens (`ET1.<hex>`):** `NodeEnrollmentBootstrapWorker` submits a PKCS#10 CSR with a single-use token and immediately scrubs `ROKKA_ENROLLMENT_TOKEN` / `ABODI_ENROLLMENT_TOKEN` and temporary token files from memory and disk.
- **ASN.1 DER SPIFFE SAN Validation (`spiffe://aarkam.cluster/node/{NodeId}`):** Direct RFC 5280 ASN.1 Tag 6 URI parsing with `ClientAuthentication`-only EKU enforcement.
- **Jittered Zero-Downtime Certificate Rotation (`CertificateRotationWorker`):** Automatically renews node X.509 certificates at **$70\% \pm 5\%$ of lifetime** and hot-swaps gRPC channels in `StorageNodeWorker` without dropping active storage streams.

### 4.2 Non-OS Storage Volume Qualification & JBOD Placement (`v1.0.2-GA`)
- **OS Partition Protection (`StorageDirectoryResolver`):** Refuses to place high-throughput Kdouja page files on the OS boot partition (`/` on Linux or `C:\` on Windows) in production (`AllowOsPartition = false`), automatically scoring and selecting healthy non-OS physical volumes (`M.2 NVMe > Enterprise SSD > HDD`).
- **Automated Write-Lock Loopback (`TelemetryMetricsWorker`):** Continuously correlates SMART health and ML degradation findings; if a volume crosses critical failure thresholds, Abodi automatically invokes `ReportVolumeStatusAsync(IsHealthy = false)` to quarantine the drive before data loss occurs.

### 4.3 Multi-Sink Serilog Observability & Durable SQLite WAL Outbox (`v1.0.1-GA`)
- **Structured Multi-Sink Logging:** Console, rolling local files, Seq, and Elasticsearch (`logs-abodi-agent-<env>`) enriched with `CorrelationId`, `WorkingSetBytes`, `ManagedMemoryBytes`, `ThreadCount`, and `NodeUptimeSeconds`.
- **Zero-Loss SQLite WAL Telemetry Outbox (`SqliteTelemetryCache`):** Buffers node telemetry during coordinator network partitions with monotonic sequence numbers, FIFO quota pruning, and a 10 GB minimum free disk space guard.

---

## 5. Deep-Dive: How Abodi Integrates with Rokka & Kdouja SAT

```
┌────────────────────────────────────────────────────────────────────────────┐
│                   Aarkam.IO Portal  /  AM Fleet CLI                        │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                      │ Admin REST / gRPC
                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                 Rokka Distributed Storage Coordinator (:57774)             │
│  • Node Enrollment CA (EnrollNode / RenewCertificate / RevokeNode)         │
│  • Consistent Hash Ring, Cauchy Reed-Solomon (K+M) Placement & Raft Epoch  │
└───────────────┬─────────────────────────────────────────────┬──────────────┘
                │ Outbound from Abodi (mTLS :57774)           │ Inbound to Abodi (mTLS :57775 / :57776)
                │ • RegisterNode & SendHeartbeat              │ • KdoujaStorageService (PrepareEpoch,
                │ • NodeManifest & Telemetry Outbox Drain     │   Allocate/Write/Read/ReleasePage, KMS)
                │ • ReportVolumeStatus (Health Quarantine)    │ • NodeHealthService (Compact, Flush, Stats)
                ▼                                             ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                     Abodi Node Daemon (v1.0.4 — :57775 / :57776)           │
│  • KdoujaGrpcAuthInterceptor (Zero-Trust mTLS / Rokka JWT / AK1.* Auth)    │
│  • Monotonic Topology Epoch Fencing (topology_epoch.state)                 │
│  • Local AES-256-GCM Envelope KMS (GenerateDataKey / DecryptDataKey)       │
│  • Hardware Collectors (CPU, RAM, SMART, NVMe, NIC) + Weibull/Holt-Winters │
│  • Aarkam.Kdouja.SDK (v1.0.1) + /healthz/kdouja                            │
└──────────────────────┬───────────────────────────────┬─────────────────────┘
                       │                               │
     Kdouja:Mode = "Embedded" (Default)      Kdouja:Mode = "Standalone"
                       │                               │ Loopback gRPC (:57771) / UDS
                       ▼                               ▼
     ┌──────────────────────────────────┐    ┌──────────────────────────────────┐
     │ Aarkam.Kdouja.SDK.Embedded       │    │ kdoujad (Aarkam.Kdouja.SAT v1.0.2)│
     │ In-Process PageStore & LSM Engine│    │ Standalone Daemon (:57771)       │
     │ Direct I/O (O_DIRECT / Unbuffered│    │ Owns LSM-Tree, AES-256 WAL &     │
     │ 256MB Segment Files)             │    │ 256MB Direct I/O PageStore Blocks│
     └──────────────────────────────────┘    └──────────────────────────────────┘
```

### Key Architectural Responsibilities
1. **Why Rokka Never Talks Directly to `kdoujad` in Standalone Mode:**
   - **Security & Zero-Trust:** `Abodi` enforces `KdoujaGrpcAuthInterceptor` (mTLS client cert validation, Rokka JWTs, and cluster-signed `AK1.*` keys) on port `57775`. Standalone `kdoujad` (`57771`) stays strictly internal on loopback (`127.0.0.1`) or an isolated container network.
   - **Split-Brain Fencing:** `Abodi`'s `KdoujaStorageService` enforces Rokka's two-phase topology epoch protocol (`PrepareEpoch` persisted to `topology_epoch.state`), rejecting stale zombie writes with `StatusCode.FailedPrecondition` before they reach Kdouja.
   - **Local KMS Envelope Wrapping:** `Abodi` mints and unwraps 256-bit DEKs (`GenerateDataKey` / `DecryptDataKey`) using the node's 256-bit master key (`KeyFileSecurityValidator`), zeroizing key bytes on shutdown.

---

## 6. Distribution Packages & Verified SHA-256 Checksums (`v1.0.4-GA`)

All native release bundles are self-contained, single-file `.NET 10.0` distributions requiring no pre-installed .NET runtime on target hosts:

| Artifact | Platform | Size | Verified SHA-256 Checksum |
| :--- | :--- | :---: | :--- |
| **`abodi-v1.0.4-linux-x64.zip`** | Linux `x86_64` | `48.22 MB` | `c11bd1d974c8e6ae739373e576e5e2f91cc274527cee273cc469d7e31b735a1a` |
| **`abodi-v1.0.4-win-x64.zip`** | Windows Server `x64` | `49.01 MB` | `efae17e40ed5ce29d3ffd5b2ac1cfd5cbc439cce98d7faf572d3666537f523fe` |
| **`aarkam/aarkam.abodi:v1.0.4`** | Docker (`linux/amd64`) | Ubuntu 24.04 Noble | Includes `smartmontools`, `nvme-cli`, `lm-sensors`, `pciutils`, `dmidecode`, `iproute2`, `ethtool`, `libsqlite3-0` |

Verify downloaded archives before installation:
```bash
# Linux
sha256sum -c SHA256SUMS.txt

# Windows PowerShell
Get-FileHash .\abodi-v1.0.4-win-x64.zip -Algorithm SHA256
```

---

## 7. Deployment & Upgrade Runbook

### 7.1 Docker Compose Deployment (Embedded vs. Standalone `kdoujad`)

#### Option A: Embedded Mode (Single Container — Default)
```bash
docker compose up -d
```

#### Option B: Standalone Mode (`Abodi` + `kdoujad` Sidecar Container)
```bash
KDOUJA_MODE=Standalone docker compose --profile standalone up -d
```

### 7.2 Bare-Metal Linux Deployment (`systemd` — Service: `Aarkam.Abodi`)
```bash
sudo mkdir -p /opt/aarkam/abodi
sudo unzip abodi-v1.0.4-linux-x64.zip -d /opt/aarkam/abodi
sudo chmod +x /opt/aarkam/abodi/Abodi /opt/aarkam/abodi/install-abodi.sh

# Omit --node-code to reuse appsettings.json or auto-generate a 15-char XXXX-XXXX-XXXXX code
sudo /opt/aarkam/abodi/install-abodi.sh \
  --rokka-url "https://rokka-coordinator.aarkam:57774" \
  --enrollment-token "ET1.YOUR_SINGLE_USE_TOKEN" \
  --storage-dir "/mnt/nvme_data01/rokka_storage"
```

### 7.3 Bare-Metal Windows Server Deployment (Windows Service — Service: `Aarkam.Abodi`)
```powershell
Expand-Archive -Path .\abodi-v1.0.4-win-x64.zip -DestinationPath "C:\Program Files\Aarkam\Abodi" -Force
Set-Location "C:\Program Files\Aarkam\Abodi"

# Omit -NodeCode to reuse appsettings.json or auto-generate a 15-char XXXX-XXXX-XXXXX code
.\install-abodi.ps1 `
  -RokkaUrl "https://rokka-coordinator.aarkam:57774" `
  -EnrollmentToken "ET1.YOUR_SINGLE_USE_TOKEN" `
  -StorageDir "D:\rokka_storage"
```

### 7.4 Post-Deployment Health Verification
```bash
# 1. Abodi Node Liveness Probe
curl -s http://127.0.0.1:7776/api/v1/health/ping

# 2. Kdouja SDK Storage Substrate Health Check (Embedded or Standalone)
curl -s http://127.0.0.1:7776/healthz/kdouja
```

---

## 8. Network Port & Protocol Matrix

| Port | Direction | Protocol | Binding | Security | Purpose |
| :---: | :---: | :---: | :---: | :--- | :--- |
| **`57775`** | Inbound | gRPC / HTTP/2 | `0.0.0.0` | **mTLS + `KdoujaGrpcAuthInterceptor`** | Rokka `KdoujaStorageService` (Page I/O, Epoch Fencing, KMS) & `NodeHealthService` |
| **`57776`** | Inbound | HTTPS / REST | `0.0.0.0` | **mTLS + Bearer / `X-Rokka-Node-Key`** | Node diagnostics, telemetry snapshots, hardware manifests, and health API |
| **`7775`** | Loopback | gRPC / HTTP/2 | `127.0.0.1` | Loopback Only | Local intra-host gRPC loopback (used by `TelemetryMetricsWorker` write-lock gate) |
| **`7776`** | Loopback | HTTP / REST | `127.0.0.1` | Loopback Only | Local host liveness (`/api/v1/health/ping`) and Kdouja health check (`/healthz/kdouja`) |
| **`57774`** | Outbound | gRPC & HTTPS | Rokka Host | **mTLS (`spiffe://aarkam.cluster/node/*`)** | Upstream Rokka Coordinator enrollment, heartbeats, manifests, and telemetry drain |
| **`57771`** | Loopback / Internal | gRPC / HTTP/2 | `127.0.0.1` / Sidecar | Internal Only | Standalone `kdoujad` (`Aarkam.Kdouja.SAT`) daemon port when `Kdouja:Mode=Standalone` |
