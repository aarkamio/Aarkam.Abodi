# Abodi Sovereign Hardware Diagnostics & Storage Node Agent
# Official Production Release Notes (Version 1.0.0-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | Abodi Sovereign Storage & Diagnostics Node Daemon |
| **Release Version** | `v1.0.0-GA (General Availability)` |
| **Release Date** | October 2026 |
| **Architectural Role** | Unified Physical Storage Node Agent & Hardware Telemetry Engine |
| **Dependency Scope** | Core Foundation for **Aarkam - SAT (Standalone Tier: Rokka Substrate)** & **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Cloud)** |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64) |

---

## 1. Executive Summary

**Abodi v1.0.0-GA** represents the official production milestone of Aarkam's hardware diagnostics, storage node agent, and telemetry daemon.

As the physical foundation of the Aarkam ecosystem, **Abodi runs on every storage node host across both tiers**:
1. **Aarkam - SAT (Standalone Tier: Rokka Sovereign Storage Substrate)**: Powers direct NVMe block I/O, sector-aligned chunk allocation for Cauchy Reed-Solomon erasure coding, and real-time health-weighted placement scores.
2. **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Sovereign Enterprise Cloud Platform)**: Feeds cluster telemetry, physical drive health, anomaly detection, and capacity planning metrics directly into the centralized management fabric.

Version 1.0.0-GA delivers complete autonomous operation in 100% disconnected, zero-egress air-gapped environments without external database dependencies, cloud callbacks, or runtime prerequisites.

---

## 2. Core Capabilities & Architectural Highlights

### 2.1 Direct I/O Kdouja PageStore & 66,048-Byte Sector Alignment
- **Direct Hardware I/O**: Eliminates operating system buffer double-caching by enforcing direct NVMe sector writes (`O_DIRECT` on Linux, `FILE_FLAG_NO_BUFFERING` on Windows).
- **Physical Sector Geometry**: Strict adherence to the 66,048-byte physical page standard (512-byte header + 64KB aligned payload).
- **Embedded Kdouja LSM Engine**: High-throughput key-value storage and write-ahead log (WAL) for local chunk indexing.
- **Physical Block Reclamation**: Full support for `ReleasePage` RPCs to dynamically reclaim freed storage on disk.

### 2.2 Medical-Reasoning Hardware Diagnostics & SMART Telemetry
- **Continuous Multi-Subsystem Harvesting**: Harvests low-level performance counters, sysfs/procfs, WMI, and NVMe controller registers across CPU, Memory, Storage, Network, and Virtualization layers.
- **Denoising & Alarm De-escalation**: Diagnostic correlation engine analyzes raw findings to suppress alarm fatigue and identify true root causes.
- **Dynamic Placement Scoring**: Computes real-time node health scores used by the Rokka placement engine to dynamically steer I/O away from saturated or degraded drives.

### 2.3 Machine Learning Failure Forecasting & Automated Evacuation
- **Predictive Reliability Models**: Implements Weibull distribution failure estimation, Holt-Winters triple exponential smoothing, and linear degradation models directly on the node.
- **Proactive Shard Evacuation**: Automatically marks deteriorating drives with `AllowWrite = false` before unrecoverable sector loss occurs, allowing the cluster to execute non-disruptive Cauchy shard reconstruction.

### 2.4 Resilient Offline Outbox (SQLite WAL Mode)
- **Zero Telemetry Loss**: Buffers local metrics, alerts, and heartbeat payloads inside an embedded SQLite write-ahead log (WAL) outbox during network partitions.
- **Monotonic Ordering & Quota Pruning**: Ensures FIFO delivery with strict disk quota guards to protect host storage.

### 2.5 Zero-Trust SPIFFE Identity & Mutual TLS
- **Dynamic Node Enrollment**: Provisions zero-trust node identity via cryptographic single-use enrollment tokens (`ET1.<hex>`).
- **mTLS Channel Encryption**: All internal node-to-coordinator traffic is authenticated and encrypted via mutual TLS (mTLS) with SPIFFE identities (`spiffe://rokka.cluster/node/*`).
- **Local Credential Protection**: Cryptographic keys protected via POSIX `0700`/`0600` permissions on Linux and DPAPI on Windows.

---

## 3. Distribution Packages & Deployment Artifacts

The standalone, self-contained native release bundles are packaged in this release directory:

| Artifact Filename | Target Platform | Contents | Size |
| :--- | :--- | :--- | :---: |
| **`abodi-v1.0.0-linux-x64.zip`** | Linux x64 (RHEL 9+, Ubuntu 22.04+) | Standalone `Abodi` ELF binary, `appsettings.json`, `install-abodi.sh`, `RELEASE_NOTES.md` | **~21 MB** |
| **`abodi-v1.0.0-win-x64.zip`** | Windows Server x64 (2022/2025) | Standalone `Abodi.exe`, `appsettings.json`, `web.config`, `install-abodi.ps1`, `RELEASE_NOTES.md` | **~21 MB** |

> [!NOTE]
> Both release archives are single-file, self-contained native distributions requiring zero external .NET runtime installations on target host servers.

---

## 4. Quick Installation Guide

### Linux Deployment (systemd Service)

1. Extract the release bundle:
   ```bash
   sudo mkdir -p /opt/rokka/abodi
   sudo unzip abodi-v1.0.0-linux-x64.zip -d /opt/rokka/abodi
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

### Windows Server Deployment (Windows Service)

1. Extract `abodi-v1.0.0-win-x64.zip` into `C:\Rokka\Abodi`.
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

## 5. Network Ports & Protocols

| Port | Protocol | Binding | Purpose |
| :---: | :---: | :---: | :--- |
| **`57775`** | gRPC / HTTP/2 (mTLS) | `0.0.0.0` | Node Kdouja Direct I/O Chunk Data Plane |
| **`7775`** | gRPC / HTTP/2 (Cleartext) | `127.0.0.1` | Local Intra-Host Storage RPC Endpoint |
| **`57776`** | HTTPS / REST (mTLS) | `0.0.0.0` | Node Telemetry, Anomaly & Control Plane |
| **`7776`** | HTTP / REST (Cleartext) | `127.0.0.1` | Local Host Diagnostics & Readiness Probe |
