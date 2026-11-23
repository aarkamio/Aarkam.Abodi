<div align="center">

<img src="https://raw.githubusercontent.com/aarkamio/Aarkam/main/docs/images/aarkam-logo.png" alt="Aarkam Logo" width="180" />

# Abodi Sovereign Storage & Diagnostics Node Daemon (`v1.0.4`)
### Rokka-Native Storage Node Gateway, Dual-Mode Kdouja SAT Substrate & Predictive Hardware Telemetry Engine

[![Version](https://img.shields.io/badge/version-v1.0.4--GA-blue.svg?style=for-the-badge&logo=semver)](https://github.com/aarkamio/Aarkam)
[![Docker Image](https://img.shields.io/badge/docker-aarkam%2Faarkam.abodi%3Av1.0.4-2496ED.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/aarkam/aarkam.abodi)
[![Kdouja SAT](https://img.shields.io/badge/Kdouja%20SAT-v1.0.2%20%7C%20SDK%20v1.0.1-purple.svg?style=for-the-badge)](https://hub.docker.com/r/aarkam/aarkam.kdouja)
[![Rokka Fabric](https://img.shields.io/badge/Rokka%20Coordinator-v1.0.2%2B%20(%3A57774)-008080.svg?style=for-the-badge)]()
[![Target OS](https://img.shields.io/badge/platform-Linux%20x64%20%7C%20Windows%20x64-333333.svg?style=for-the-badge&logo=linux)](https://github.com/aarkamio/Aarkam)
[![Compliance](https://img.shields.io/badge/compliance-NCA%20ECC--2%3A2024%20%7C%20FIPS%20140--3-darkgreen.svg?style=for-the-badge)](https://github.com/aarkamio/Aarkam)

</div>

---

## 1. Overview: Abodi, Rokka, and Kdouja SAT

**Aarkam Abodi (`v1.0.4`)** is the containerized and bare-metal node agent deployed on every storage server within the **Rokka Distributed Storage Fabric**. Built on **.NET 10.0**, Abodi unifies three mission-critical responsibilities on each storage host:

1. **Rokka Storage Node Gateway & Zero-Trust Boundary (`:57775` / `:57776`):** Enrolls with the **Rokka Coordinator (`:57774`)** using single-use tokens (`ET1.<hex>`) and ECDSA P-256 mutual TLS (`spiffe://aarkam.cluster/node/{NodeCode}`), enforces monotonic Raft topology epoch fencing (`PrepareEpoch` / `topology_epoch.state`), and performs local AES-256-GCM Data Encryption Key (DEK) envelope wrapping (`GenerateDataKey` / `DecryptDataKey`).
2. **Dual-Mode Kdouja SAT Storage Integration (`Aarkam.Kdouja.SDK v1.0.1`):** Supports both **Embedded Mode** (in-process Kdouja Direct I/O `PageStore` inside the `abodi` container) and **Standalone Sidecar Mode** (connecting to an isolated **`kdoujad` (`aarkam/aarkam.kdouja:v1.0.2`)** container over `:57771`).
3. **Medical-Reasoning Hardware Diagnostics & Predictive Evacuation:** Harvests physical NVMe/SATA S.M.A.R.T. registers, CPU/memory/thermal sensors, and NIC counters; runs Weibull and Holt-Winters failure forecasting; buffers telemetry in a zero-loss SQLite WAL outbox; and automatically quarantines degrading drives (`AllowWrite = false`) before sector loss occurs.

---

## 2. Valid Version & Ecosystem Compatibility Matrix

Ensure your container tags and NuGet dependencies match the validated **Aarkam V2** compatibility matrix below:

| Component | Valid Version / Tag | Container Image / NuGet Package | Port(s) | Role in Container Stack |
| :--- | :---: | :--- | :---: | :--- |
| **Aarkam Abodi** | **`v1.0.4`** (`latest`) | `aarkam/aarkam.abodi:v1.0.4` | `57775`, `57776`, `7775`, `7776` | Primary Node Daemon, Rokka mTLS Gateway & Hardware Telemetry Agent |
| **Aarkam Kdouja SAT** | **`v1.0.2`** (`latest`) | `aarkam/aarkam.kdouja:v1.0.2` | `57771` *(internal)* | Standalone LSM-Tree & Direct I/O Block Daemon (`kdoujad` sidecar) |
| **`Aarkam.Kdouja.SDK`** | **`1.0.1`** | `Aarkam.Kdouja.SDK` (+ `.Embedded`, `.Remote`, `.AspNetCore`) | — | Unified .NET 10 SDK embedded in Abodi `v1.0.4` for Dual-Mode Kdouja |
| **`Aarkam.Kdouja.Primitives`** | **`1.0.6`** | `Aarkam.Kdouja.Primitives` | — | Zero-allocation Direct I/O buffers & CRC32 parity primitives |
| **Aarkam Rokka Coordinator** | **`v1.0.2+`** (`v2.1`) | `Rokka.Coordinator` (`Rokka.Contracts 1.0.2`) | `57774` | Cluster Consensus Coordinator, Node CA, Erasure Coding & Placement |

### Supported `aarkam/aarkam.abodi` Container Tags

| Tag | Architecture | Base Image | Pre-Installed Hardware Diagnostic Tools |
| :--- | :---: | :--- | :--- |
| **`v1.0.4`**, **`1.0.4`**, **`latest`** | `linux/amd64` (`x86_64`) | `mcr.microsoft.com/dotnet/aspnet:10.0-noble` (Ubuntu 24.04 LTS) | `smartmontools`, `nvme-cli`, `util-linux` (`lsblk`), `pciutils`, `dmidecode`, `lm-sensors`, `iproute2`, `ethtool`, `libsqlite3-0`, `curl` |
| `v1.0.3`, `1.0.3` | `linux/amd64` (`x86_64`) | `mcr.microsoft.com/dotnet/aspnet:10.0-noble` | Dual-mode Kdouja SAT SDK v1.0.1 integration release |
| `v1.0.2`, `1.0.2` | `linux/amd64` (`x86_64`) | `mcr.microsoft.com/dotnet/aspnet:10.0-noble` | Legacy single-mode release (prior to `Aarkam.Kdouja.SDK v1.0.1` integration) |

---

## 3. Architectural Integration: Rokka $\leftrightarrow$ Abodi $\leftrightarrow$ Kdouja SAT

```
┌────────────────────────────────────────────────────────────────────────────┐
│                 Rokka Storage Coordinator Cluster (:57774)                 │
│  • Issues X.509 Node Client Certs via Single-Use Token (ET1.<hex>)         │
│  • Assigns Cauchy Reed-Solomon (K+M) Shards & Topology Epochs              │
│  • Ingests Abodi Hardware Manifests, Heartbeats & SMART Health Scores      │
└───────────────┬─────────────────────────────────────────────┬──────────────┘
                │ Outbound mTLS (:57774)                      │ Inbound mTLS (:57775 / :57776)
                │ • NodeEnrollmentBootstrapWorker             │ • KdoujaStorageService (gRPC :57775)
                │ • StorageNodeWorker (Heartbeat/Volumes)     │ • NodeHealthService (gRPC :57775)
                │ • TelemetryMetricsWorker (SQLite Outbox)    │ • Diagnostics REST API (HTTPS :57776)
                ▼                                             ▼
┌────────────────────────────────────────────────────────────────────────────┐
│             aarkam/aarkam.abodi:v1.0.4 Container (Abodi Daemon)            │
│  • Zero-Trust Auth (KdoujaGrpcAuthInterceptor + SPIFFE SAN Verification)   │
│  • Split-Brain Epoch Fencing (PrepareEpoch -> topology_epoch.state)        │
│  • Local AES-256-GCM Envelope KMS (GenerateDataKey / DecryptDataKey)       │
│  • Non-OS Drive Qualification (StorageDirectoryResolver + SMART Gate)      │
│  • Aarkam.Kdouja.SDK v1.0.1 + Health Check (/healthz/kdouja)               │
└──────────────────────┬───────────────────────────────┬─────────────────────┘
                       │                               │
     Kdouja__Mode=Embedded (Default)         Kdouja__Mode=Standalone (--profile standalone)
                       │                               │ Internal gRPC (http://kdoujad:57771)
                       ▼                               ▼
     ┌──────────────────────────────────┐    ┌──────────────────────────────────┐
     │ In-Process Kdouja Engine         │    │ aarkam/aarkam.kdouja:v1.0.2      │
     │ (Aarkam.Kdouja.SDK.Embedded)     │    │ (abodi-kdoujad Sidecar Container)│
     │ • Direct I/O PageStore           │    │ • Standalone kdoujad Daemon      │
     │ • Writes to /var/lib/aarkam/     │    │ • LSM-Tree + AES-256 WAL         │
     │   storage                        │    │ • Shared abodi_storage Volume    │
     └──────────────────────────────────┘    └──────────────────────────────────┘
```

### 3.1 How Abodi Works with Kdouja SAT (Dual-Mode)
- **Mode 1 — Embedded Mode (`Kdouja__Mode=Embedded`, Default):**
  - Uses `Aarkam.Kdouja.SDK.Embedded` (`1.0.1`) and `PageStore` in-process inside the `abodi` container.
  - Bypasses the Linux kernel page cache (`O_DIRECT` when `EnableDirectIO=true`) and writes 256 MB pre-allocated segment files (`segment_*.aarkam`) directly to `/var/lib/aarkam/storage`.
  - Ideal for single-container edge deployments and standard storage nodes.
- **Mode 2 — Standalone Sidecar Mode (`Kdouja__Mode=Standalone`):**
  - Uses `Aarkam.Kdouja.SDK.Remote` (`1.0.1`) inside `abodi` to communicate with the **`aarkam/aarkam.kdouja:v1.0.2` (`kdoujad`)** container on port `57771`.
  - `kdoujad` owns the LSM-Tree (`KeyValueEngine`), AES-256 encrypted Write-Ahead Log (WAL), SIMD xxHash64 Bloom filters, background SSTable compaction, and Direct I/O `PageStore` blocks.
  - `abodi` remains the sole externally exposed container (`57775`/`57776`), shielding `kdoujad` behind Zero-Trust mTLS authentication, Rokka epoch fencing, and hardware health gating.

### 3.2 How Abodi Works with Rokka Coordinator
- **Strict Control Hierarchy:** External tools (`Aarkam.IO`, `AM CLI`) never connect directly to `Abodi` or `Kdouja`; they communicate strictly with **Rokka Coordinator (`:57774`)**.
- **Zero-Trust Onboarding & Rotation:**
  1. Administrator generates a single-use token on Rokka: `am node token create --node-id <NodeCode> --role storage-node`.
  2. On first boot, Abodi generates an on-node ECDSA P-256 private key in `/var/lib/aarkam/security/node-identity.key` (`0600`), submits a PKCS#10 CSR to Rokka, persists the signed X.509 certificate (`node-identity.crt`), and **permanently deletes** the bootstrap token.
  3. `CertificateRotationWorker` automatically renews the certificate at **$70\% \pm 5\%$ of lifetime** and hot-swaps active gRPC channels in `StorageNodeWorker` with zero downtime.
- **Continuous Health-Qualified Placement & Quarantine:**
  - `NodeManifestWorker` and `StorageNodeWorker` report hardware capabilities, free capacity, and heartbeats to Rokka.
  - If `StorageDiagnosticsAnalyzer` or `DiskLifePredictor` detects critical SMART wear ($\ge 90\%$), uncorrectable media errors, or imminent failure, `TelemetryMetricsWorker` triggers an immediate write-lock (`ReportVolumeStatusAsync(IsHealthy = false)`) so Rokka stops allocating new Cauchy Reed-Solomon shards to the degraded volume and initiates proactive reconstruction.

---

## 4. Quick Start & Docker Deployment Guides

### 4.1 Prerequisites for Containerized Storage Nodes
> [!IMPORTANT]
> 1. **Persist `/var/lib/aarkam/security` on the Host:** Because Rokka enrollment tokens (`ET1.*`) are **single-use**, Abodi consumes the token on first boot and saves `node-identity.key` + `node-identity.crt` into `/var/lib/aarkam/security`. Always mount this path to a persistent host volume so container restarts/upgrades reuse the enrolled mTLS identity.
> 2. **Grant Hardware Device Access (`SYS_RAWIO` + `SYS_ADMIN`):** Required so `smartctl` and `nvme-cli` inside the container can read physical NVMe/SATA S.M.A.R.T. registers via `/dev` and `/sys`.
> 3. **Outbox Free Space Guard:** Ensure the host volume backing `/var/lib/aarkam/outbox` has **$> 10\text{ GB}$ free space** (Abodi enforces a 10 GB disk exhaustion guard on the SQLite WAL outbox).

---

### 4.2 Option A: Docker Compose — Embedded Kdouja Mode (Default)

Uses the repository's [`docker-compose.yml`](docker-compose.yml) to run `aarkam/aarkam.abodi:v1.0.4` with in-process Kdouja storage:

```bash
# Start Abodi in Embedded Kdouja mode (default)
docker compose up -d

# Follow structured startup logs
docker logs -f abodi-node
```

---

### 4.3 Option B: Docker Compose — Standalone `kdoujad` Sidecar Mode

Launches both **`aarkam/aarkam.abodi:v1.0.4`** (`abodi-node`) and **`aarkam/aarkam.kdouja:v1.0.2`** (`abodi-kdoujad`) using the `standalone` Compose profile:

```bash
# Start Abodi + standalone kdoujad sidecar
KDOUJA_MODE=Standalone docker compose --profile standalone up -d

# Verify both containers are healthy
docker compose --profile standalone ps
```

Reference `docker-compose.yml` structure (included in repository):
```yaml
services:
  abodi:
    image: ${DOCKER_REGISTRY-}aarkam/aarkam.abodi:v1.0.4
    build:
      context: .
      dockerfile: Dockerfile.release
    container_name: abodi-node
    restart: unless-stopped
    cap_add:
      - SYS_RAWIO
      - SYS_ADMIN
    devices:
      - "/dev:/dev"
    ports:
      - "7776:7776"     # HTTP REST (Local Health & Diagnostics Probe)
      - "57776:57776"   # HTTPS REST (mTLS Control & Telemetry Plane)
      - "7775:7775"     # gRPC Cleartext (Local Host Data Plane)
      - "57775:57775"   # gRPC mTLS (Kdouja PageStore Data Plane)
    volumes:
      - abodi_security:/var/lib/aarkam/security
      - abodi_outbox:/var/lib/aarkam/outbox
      - abodi_storage:/var/lib/aarkam/storage
      - abodi_logs:/var/log/aarkam/aarkam.abodi
      - /sys:/sys:ro
      - /proc:/proc:ro
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - DOTNET_CLI_TELEMETRY_OPTOUT=1
      - AgentConfiguration__NodeCode=NODE-CONTAINER-01
      - AgentConfiguration__RokkaUrl=https://rokka-coordinator.aarkam:57774
      - ABODI_API_KEY=${ABODI_API_KEY:-AARKAM_NODE_PROD_SECRET_KEY_CHANGE_ME}
      - Kdouja__Mode=${KDOUJA_MODE:-Embedded}
      - Kdouja__Embedded__BaseDirectory=/var/lib/aarkam/storage/kdouja
      - Kdouja__Standalone__Endpoint=${KDOUJA_ENDPOINT:-http://kdoujad:57771}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:7776/api/v1/health/ping"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  kdoujad:
    image: ${DOCKER_REGISTRY-}aarkam/aarkam.kdouja:v1.0.2
    profiles: ["standalone"]
    container_name: abodi-kdoujad
    restart: unless-stopped
    volumes:
      - abodi_storage:/var/lib/kdouja
    environment:
      - KDOUJA_BASE_DIRECTORY=/var/lib/kdouja
      - KDOUJA_ENABLE_DIRECT_IO=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:57771/healthz"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

volumes:
  abodi_security:
  abodi_outbox:
  abodi_storage:
  abodi_logs:
```

---

### 4.4 Option C: Direct `docker run` CLI

```bash
docker run -d \
  --name abodi-node \
  --restart unless-stopped \
  --cap-add=SYS_RAWIO \
  --cap-add=SYS_ADMIN \
  --device=/dev:/dev \
  -v /var/lib/rokka/security:/var/lib/aarkam/security \
  -v /var/lib/rokka/outbox:/var/lib/aarkam/outbox \
  -v /mnt/nvme_data01/rokka_storage:/var/lib/aarkam/storage \
  -v /var/log/rokka/abodi:/app/logs \
  -v /sys:/sys:ro \
  -v /proc:/proc:ro \
  -p 57775:57775 \
  -p 57776:57776 \
  -p 7776:7776 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e AgentConfiguration__NodeCode="STORAGE-NODE-01" \
  -e AgentConfiguration__RokkaUrl="https://rokka-coordinator.aarkam:57774" \
  -e ROKKA_IDENTITY_STORAGE_DIR="/var/lib/aarkam/security" \
  -e ROKKA_ENROLLMENT_TOKEN_FILE="/var/lib/aarkam/security/bootstrap-enrollment.token" \
  -e Storage__DataDirectory="/var/lib/aarkam/storage" \
  -e Storage__EnableDirectIO="true" \
  -e Kdouja__Mode="Embedded" \
  aarkam/aarkam.abodi:v1.0.4
```

---

## 5. Complete Environment Variable Reference

### 5.1 Rokka Coordinator & Zero-Trust Identity
| Environment Variable | Default | Description |
| :--- | :--- | :--- |
| `AgentConfiguration__NodeCode` | `"N-1"` | Unique node identifier registered in the Rokka hash ring. |
| `AgentConfiguration__RokkaUrl` | `"https://localhost:57774"` | Upstream Rokka Coordinator HTTPS/gRPC address. |
| `AgentConfiguration__LocalStorageGrpcUrl` | `"http://localhost:7775"` | Local loopback gRPC endpoint used by `TelemetryMetricsWorker` for automated drive write-lock calls. |
| `ROKKA_IDENTITY_STORAGE_DIR` | `/var/lib/aarkam/security` | Persistent directory storing `node-identity.key` (`0600`), `node-identity.crt`, and `ca-chain.crt`. |
| `ROKKA_ENROLLMENT_TOKEN` | *Unset* | Single-use `ET1.<hex>` enrollment token (scrubbed from process environment immediately upon read). |
| `ROKKA_ENROLLMENT_TOKEN_FILE` | *Unset* | Path to single-use token file (permanently deleted immediately after CSR enrollment). |
| `ABODI_API_KEY` | *Required in Prod* | Node authentication key or cluster-signed `AK1.*` key (scrubbed from environment by `KdoujaVaultSecurityProvider`). |

### 5.2 Kdouja SAT SDK & Storage Configuration
| Environment Variable | Default | Description |
| :--- | :--- | :--- |
| `Kdouja__Mode` | `"Embedded"` | Kdouja execution mode: `"Embedded"` (in-process) or `"Standalone"` (`kdoujad` sidecar). |
| `Kdouja__Embedded__BaseDirectory` | `"abodi_data/kdouja"` | Directory for embedded Kdouja LSM-Tree & WAL files. |
| `Kdouja__Embedded__EnableDirectIO` | `false` (`true` on bare-metal NVMe) | Enables unbuffered hardware Direct I/O (`O_DIRECT` / `FILE_FLAG_NO_BUFFERING`). |
| `Kdouja__Embedded__PageSizeBytes` | `4096` | Logical page block size in bytes. |
| `Kdouja__Embedded__EnableWalFsync` | `true` | Forces hardware `fsync` on every WAL commit. |
| `Kdouja__Standalone__Endpoint` | `"http://127.0.0.1:57771"` | gRPC endpoint of the standalone `kdoujad` daemon (`http://kdoujad:57771` in Docker Compose). |
| `Kdouja__Standalone__EnableRetry` | `true` | Enables automatic gRPC retry resilience on transient connection failures to `kdoujad`. |
| `Storage__DataDirectory` | `"abodi_data"` | Primary directory used by `PageStore` and `StorageDirectoryResolver`. |
| `Storage__AllowOsPartition` | `false` (Prod) | Set to `true` (or `ABODI_ALLOW_OS_PARTITION=true`) in single-disk container/dev environments. |

### 5.3 Telemetry Outbox, OpenTelemetry & Serilog Sinks
| Environment Variable | Default | Description |
| :--- | :--- | :--- |
| `TelemetryOutbox__DatabasePath` | `abodi-telemetry.db` | Path to the SQLite WAL offline telemetry outbox database. |
| `OpenTelemetry__Endpoint` | `"http://localhost:4317"` | OTLP gRPC exporter endpoint for `Abodi.Agent` and `Aarkam.Kdouja.SDK` traces & metrics. |
| `SerilogConfig__MinimumLevel` | `"Information"` | Minimum log level (`Verbose`, `Debug`, `Information`, `Warning`, `Error`, `Fatal`). |
| `SerilogConfig__WriteToConsole` | `true` | Streams structured logs to container stdout. |
| `SerilogConfig__WriteToFile` | `true` | Writes rolling log files to `/app/logs` (`SerilogConfig__LogDirectory`). |
| `SerilogConfig__WriteToSeq` | `false` | Enables real-time Seq ingestion (`SerilogConfig__SeqUrl`, `SerilogConfig__SeqApiKey`). |
| `SerilogConfig__WriteToElasticsearch` | `false` | Enables Elasticsearch data stream indexing (`SerilogConfig__ElasticsearchUrl`). |

---

## 6. Network Ports, Volumes & Health Probes

### 6.1 Exposed Container Ports
| Port | Protocol | Binding | Security | Purpose |
| :---: | :---: | :---: | :--- | :--- |
| **`57775`** | gRPC (HTTP/2) | `0.0.0.0` | **mTLS + `KdoujaGrpcAuthInterceptor`** | Rokka `KdoujaStorageService` (Page I/O, Epoch Fencing, KMS) & `NodeHealthService` |
| **`57776`** | HTTPS (HTTP/1.1 & HTTP/2) | `0.0.0.0` | **mTLS + Bearer / Node Key** | REST Diagnostics, Telemetry, Hardware Manifests & Health API |
| **`7775`** | gRPC (HTTP/2) | `127.0.0.1` | Cleartext Loopback | Local intra-container gRPC loopback |
| **`7776`** | HTTP (HTTP/1.1) | `127.0.0.1` | Cleartext Loopback | Local container healthcheck (`/api/v1/health/ping` & `/healthz/kdouja`) |

### 6.2 Persistent Container Volumes
| Container Mount Path | Recommended Host Backing | Purpose |
| :--- | :--- | :--- |
| `/var/lib/aarkam/security` | Persistent host directory (`chmod 0700`) | Zero-Trust ECDSA P-256 private key (`node-identity.key`), X.509 client cert, and CA chain. |
| `/var/lib/aarkam/outbox` | Host volume with $> 12\text{ GB}$ free | SQLite WAL telemetry outbox (`abodi-telemetry.db`). |
| `/var/lib/aarkam/storage` | Dedicated non-OS NVMe/SSD mount | Kdouja `PageStore` segments (`segment_*.aarkam`) and `topology_epoch.state` fence file. |
| `/var/log/aarkam/abodi` / `/app/logs` | Host log partition | Rolling structured diagnostic logs. |

### 6.3 Health Check Endpoints
```bash
# 1. Abodi Liveness Probe (used by Docker HEALTHCHECK)
curl -f http://127.0.0.1:7776/api/v1/health/ping

# 2. Aarkam.Kdouja.SDK Storage Engine Health Probe (Embedded or Standalone kdoujad)
curl -f http://127.0.0.1:7776/healthz/kdouja
```

---

## 7. Building the Production Image Locally

The repository provides two Dockerfiles:
1. **`Dockerfile.release` (Production Release Image):** Packages the verified self-contained Linux release payload from `dist/linux/` (generated by `scripts/build-release.ps1`).
2. **`src/Abodi/Dockerfile` (SDK Multi-Stage Build):** Compiles directly from source using `mcr.microsoft.com/dotnet/sdk:10.0` and restores `Aarkam.Kdouja.SDK` (`1.0.1`) from NuGet.org.

```powershell
# 1. Regenerate v1.0.4 release bundles and stage dist/linux
.\scripts\build-release.ps1 -Version "1.0.4" -ReleaseTag "v1.0.4"

# 2. Build the production container image
docker build -f Dockerfile.release -t aarkam/aarkam.abodi:v1.0.4 -t aarkam/aarkam.abodi:latest .
```

---

<div align="center">
<sub>Copyright &copy; 2026 Aarkam.IO. All rights reserved. Sovereign Cloud, Rokka Distributed Storage Fabric & Kdouja SAT Substrate.</sub>
</div>
