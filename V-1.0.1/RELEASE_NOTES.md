# Abodi Sovereign Hardware Diagnostics & Storage Node Agent
# Official Production Release Notes (Version 1.0.1-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | Abodi Sovereign Storage & Diagnostics Node Daemon |
| **Release Version** | `v1.0.1-GA (General Availability)` |
| **Release Date** | November 2026 |
| **Architectural Role** | Unified Physical Storage Node Agent & Hardware Telemetry Engine |
| **Dependency Scope** | Core Foundation for **Aarkam - SAT (Standalone Tier: Rokka Substrate)** & **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Cloud)** |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64) |

---

## 1. Executive Summary

**Abodi v1.0.1-GA** builds upon the `v1.0.0-GA` milestone with multi-sink structured Serilog observability (`Console`, `File`, `Seq`, `Elasticsearch`) with `CorrelationId`/environment/process footprint enrichment, live storage telemetry enhancements, deterministic OS process handle lifecycle management, and comprehensive XML API documentation across all assemblies.

As the physical foundation of the Aarkam ecosystem, **Abodi runs on every storage node host across both tiers**:
1. **Aarkam - SAT (Standalone Tier: Rokka Sovereign Storage Substrate)**: Powers direct NVMe block I/O, sector-aligned chunk allocation for Cauchy Reed-Solomon erasure coding, and real-time health-weighted placement scores.
2. **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Sovereign Enterprise Cloud Platform)**: Feeds cluster telemetry, physical drive health, anomaly detection, and capacity planning metrics directly into the centralized management fabric.

Version 1.0.1-GA delivers complete autonomous operation in 100% disconnected, zero-egress air-gapped environments without external database dependencies, cloud callbacks, or runtime prerequisites.

---

## 2. What's New in Version 1.0.1-GA

### 2.1 Multi-Sink Structured Serilog Observability & Footprint Enrichment
- **Configured Console, File, Seq, and Elasticsearch Sinks (`SerilogConfiguration`)**: Full support for structured logging across Console, rolling hourly local files (`100 MB` limit, shared writes, configurable retention), Seq (`WriteToSeq`, `SeqUrl`, `SeqApiKey`), and Elasticsearch data streams (`WriteToElasticsearch`, `logs-abodi-agent-<env>`).
- **CorrelationId, Environment & Process Footprint Enrichers (`SerilogFootprintMiddleware`)**: Automatically enriches every HTTP/gRPC request and background worker cycle with `CorrelationId` (`X-Correlation-ID`), `TraceId`, `SpanId`, `MachineName`, `EnvironmentName`, `EnvironmentUserName`, `ProcessId`, `ProcessName`, `ThreadId`, `ClientIp`, `NodeCode`, `OSDescription`, `OSArchitecture`, `WorkingSetBytes`, `ManagedMemoryBytes`, `ThreadCount`, and `NodeUptimeSeconds`.
- **Deep Multi-Level Structured Telemetry (`Log.Verbose` to `Log.Fatal`)**: Over 700 structured `Log.*` telemetry checkpoints across all collectors, diagnostic analyzers, ML failure predictors, SQLite WAL outbox operations, zero-trust security validators, and background workers.

### 2.2 Storage Telemetry, OS Collector & XML Documentation Enhancements
- **End-to-End Storage Telemetry Harvesting**: `StorageCollector.CollectTelemetryAsync` correlates `IDiskInventoryProvider`, `IDiskSmartHealthCollector`, and `IDiskPerformanceProvider` to emit full `List<DiskTelemetry>` payloads (SMART wear percentage, temperature, media errors, read/write throughput, IOPS, queue depth, and latency) directly into `SnapshotBuilder`.
- **Deterministic Process Handle Disposal**: Fixed `OSCollector.CollectTelemetryAsync` and `HealthController` to deterministically dispose all `System.Diagnostics.Process` handles after sampling, eliminating OS handle leaks over multi-month daemon uptimes.
- **Comprehensive XML Documentation**: Added deep architectural `<summary>` and `<remarks>` XML documentation across every class, interface, record, struct, and enum, shipping compiled `.xml` documentation alongside all assemblies.

---

## 3. Core Capabilities & Architectural Highlights

### 3.1 Direct I/O Kdouja PageStore & 66,048-Byte Sector Alignment
- **Direct Hardware I/O**: Eliminates operating system buffer double-caching by enforcing direct NVMe sector writes (`O_DIRECT` on Linux, `FILE_FLAG_NO_BUFFERING` on Windows).
- **Physical Sector Geometry**: Strict adherence to the 66,048-byte physical page standard (512-byte header + 64KB aligned payload).
- **Embedded Kdouja LSM Engine**: High-throughput key-value storage and write-ahead log (WAL) for local chunk indexing.
- **Physical Block Reclamation**: Full support for `ReleasePage` RPCs to dynamically reclaim freed storage on disk.

### 3.2 Medical-Reasoning Hardware Diagnostics & SMART Telemetry
- **Continuous Multi-Subsystem Harvesting**: Harvests low-level performance counters, sysfs/procfs, WMI, and NVMe controller registers across CPU, Memory, Storage, Network, and Virtualization layers.
- **Denoising & Alarm De-escalation**: Diagnostic correlation engine analyzes raw findings to suppress alarm fatigue and identify true root causes.
- **Dynamic Placement Scoring**: Computes real-time node health scores used by the Rokka placement engine to dynamically steer I/O away from saturated or degraded drives.

### 3.3 Machine Learning Failure Forecasting & Automated Evacuation
- **Predictive Reliability Models**: Implements Weibull distribution failure estimation, Holt-Winters double exponential smoothing, and OLS linear degradation models directly on the node.
- **Proactive Shard Evacuation**: Automatically marks deteriorating drives with `AllowWrite = false` before unrecoverable sector loss occurs, allowing the cluster to execute non-disruptive Cauchy shard reconstruction.

### 3.4 Resilient Offline Outbox (SQLite WAL Mode)
- **Zero Telemetry Loss**: Buffers local metrics, alerts, and heartbeat payloads inside an embedded SQLite write-ahead log (WAL) outbox during network partitions.
- **Monotonic Ordering & Quota Pruning**: Ensures FIFO delivery with strict disk quota guards to protect host storage.

### 3.5 Zero-Trust SPIFFE Identity & Mutual TLS
- **Dynamic Node Enrollment**: Provisions zero-trust node identity via cryptographic single-use enrollment tokens (`ET1.<hex>`).
- **mTLS Channel Encryption**: All internal node-to-coordinator traffic is authenticated and encrypted via mutual TLS (mTLS) with SPIFFE identities (`spiffe://rokka.cluster/node/*`).
- **Local Credential Protection**: Cryptographic keys protected via POSIX `0700`/`0600` permissions on Linux and NTFS ACLs on Windows.

---

## 4. Distribution Packages & Deployment Artifacts

The standalone native release bundles and official container images are distributed as follows:

| Artifact / Distribution | Target Platform | Contents | Size / Link |
| :--- | :--- | :--- | :---: |
| **`abodi-v1.0.1-linux-x64.zip`** | Linux x64 (RHEL 9+, Ubuntu 22.04+) | Standalone `Abodi` ELF binary, XML docs, `appsettings.json`, `install-abodi.sh` | **~51 MB** |
| **`abodi-v1.0.1-win-x64.zip`** | Windows Server x64 (2022/2025) | Standalone `Abodi.exe`, XML docs, `appsettings.json`, `web.config`, `install-abodi.ps1` | **~52 MB** |
| **`aarkam/aarkam.abodi:v1.0.1`** | OCI / Docker Container (Linux x64) | Enterprise hardened container image with embedded `smartmontools`, `nvme-cli`, `lm-sensors`, `iproute2` | [Docker Hub Repository](https://hub.docker.com/r/aarkam/aarkam.abodi) |

> [!NOTE]
> Both native release archives are single-file, self-contained distributions requiring zero external .NET runtime installations on target host servers. The Docker image is available on Docker Hub under the `aarkam` organization.

---

## 5. Quick Installation Guide

### 5.1 Docker Container Deployment (Docker Hub)

Abodi is officially published to Docker Hub at [https://hub.docker.com/r/aarkam/aarkam.abodi](https://hub.docker.com/r/aarkam/aarkam.abodi) (`aarkam/aarkam.abodi:v1.0.1`).

#### A. Run via Docker CLI (Direct I/O Hardware Mode)
```bash
docker run -d \
  --name rokka-abodi \
  --restart unless-stopped \
  --cap-add=SYS_RAWIO \
  --device=/dev/nvme0n1 \
  -v /var/lib/rokka/storage:/var/lib/rokka/storage \
  -v /var/lib/rokka/keys:/var/lib/rokka/keys \
  -p 57775:57775 \
  -p 57776:57776 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e Node__NodeCode="NODE-DOCKER-01" \
  -e Rokka__CoordinatorUrl="https://rokka-coordinator.rokka.internal:57774" \
  aarkam/aarkam.abodi:v1.0.1
```

#### B. Run via Docker Compose
```yaml
services:
  abodi:
    image: aarkam/aarkam.abodi:v1.0.1
    container_name: abodi-agent
    restart: unless-stopped
    cap_add:
      - SYS_RAWIO
    devices:
      - /dev/nvme0n1:/dev/nvme0n1:rwm
    volumes:
      - /var/lib/rokka/storage:/var/lib/rokka/storage
      - /var/lib/rokka/keys:/var/lib/rokka/keys
      - /var/log/rokka:/app/logs
    ports:
      - "57775:57775"
      - "57776:57776"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - Node__NodeCode=NODE-STORAGE-01
      - Rokka__CoordinatorUrl=https://rokka-coordinator.rokka.internal:57774
```

---

### 5.2 Linux Deployment (systemd Service)

1. Extract the release bundle:
   ```bash
   sudo mkdir -p /opt/rokka/abodi
   sudo unzip abodi-v1.0.1-linux-x64.zip -d /opt/rokka/abodi
   chmod +x /opt/rokka/abodi/Abodi /opt/rokka/abodi/install-abodi.sh
   ```

2. Execute the automated production installer:
   ```bash
   sudo /opt/rokka/abodi/install-abodi.sh \
     --node-code "node-prod-01" \
     --rokka-url "https://rokka-coordinator.rokka.internal:57774" \
     --enrollment-token "ET1.YOUR_TOKEN_HERE" \
     --storage-dir "/var/lib/rokka/storage"
   ```

3. Verify service status:
   ```bash
   sudo systemctl status rokka-abodi
   sudo journalctl -u rokka-abodi -f
   ```

---

### 5.3 Windows Server Deployment (Windows Service)

1. Extract `abodi-v1.0.1-win-x64.zip` into `C:\Rokka\Abodi`.
2. Open PowerShell as Administrator and run:
   ```powershell
   Set-Location "C:\Rokka\Abodi"
   .\install-abodi.ps1 `
     -NodeCode "NODE-WIN-01" `
     -RokkaUrl "https://rokka-coordinator.rokka.internal:57774" `
     -EnrollmentToken "ET1.YOUR_TOKEN_HERE" `
     -StorageDir "D:\rokka_storage"
   ```
3. Verify service status:
   ```powershell
   Get-Service -Name "Rokka.Abodi.Agent"
   ```

---

## 6. Network Ports & Protocols

| Port | Protocol | Binding | Purpose |
| :---: | :---: | :---: | :--- |
| **`57775`** | gRPC / HTTP/2 (mTLS) | `0.0.0.0` | Node Kdouja Direct I/O Chunk Data Plane |
| **`7775`** | gRPC / HTTP/2 (Cleartext) | `127.0.0.1` | Local Intra-Host Storage RPC Endpoint |
| **`57776`** | HTTPS / REST (mTLS) | `0.0.0.0` | Node Telemetry, Anomaly & Control Plane |
| **`7776`** | HTTP / REST (Cleartext) | `127.0.0.1` | Local Host Diagnostics & Readiness Probe |
