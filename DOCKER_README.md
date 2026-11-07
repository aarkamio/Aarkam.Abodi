<div align="center">

<img src="https://raw.githubusercontent.com/aarkamio/Aarkam/main/docs/images/aarkam-logo.png" alt="Aarkam Logo" width="180" />

# Abodi Sovereign Storage & Diagnostics Node Daemon
### Unified Physical Storage Node Agent, Direct NVMe I/O Substrate & Medical-Reasoning Hardware Telemetry Engine

[![Version](https://img.shields.io/badge/version-v1.0.2--GA-blue.svg?style=for-the-badge&logo=semver)](https://github.com/aarkamio/Aarkam)
[![Docker Image](https://img.shields.io/badge/docker-aarkam%2Faarkam.abodi-2496ED.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/aarkam/aarkam.abodi)
[![Target OS](https://img.shields.io/badge/platform-Linux%20x64%20%7C%20Windows%20x64-333333.svg?style=for-the-badge&logo=linux)](https://github.com/aarkamio/Aarkam)
[![Architecture](https://img.shields.io/badge/arch-x86__64%20(AVX2)-orange.svg?style=for-the-badge)](https://github.com/aarkamio/Aarkam)
[![Compliance](https://img.shields.io/badge/compliance-NCA%20ECC--2%3A2024%20%7C%20FIPS%20140--3-darkgreen.svg?style=for-the-badge)](https://github.com/aarkamio/Aarkam)
[![Air-Gapped](https://img.shields.io/badge/network-100%25%20Air--Gapped%20Zero--Egress-critical.svg?style=for-the-badge)](https://github.com/aarkamio/Aarkam)

</div>

---

## 1. What is Abodi?

**Abodi** is the physical foundation and high-performance node agent of the **Aarkam Sovereign Data Fabric**. Operating directly on bare-metal and containerized storage nodes, Abodi delivers low-level hardware inspection, sub-millisecond direct NVMe block I/O, medical-grade diagnostic correlation, and zero-loss telemetry streaming across distributed sovereign cloud environments.

Abodi serves as the fundamental storage engine and hardware watchdog for both operational tiers of the Aarkam ecosystem:

1. **Aarkam - SAT (Standalone Tier: Rokka Sovereign Storage Substrate)**: Powers direct sector-level NVMe writes (`O_DIRECT`), 66,048-byte physical page alignment, Cauchy Reed-Solomon erasure coding shard placement, and real-time health-weighted routing.
2. **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Sovereign Enterprise Cloud Platform)**: Continuously streams hardware vitals, SMART lifecycle telemetry, predictive degradation forecasts, and cluster capacity analytics into the centralized sovereign operations fabric.

Engineered strictly for **zero-egress, air-gapped sovereign datacenters**, Abodi operates with complete autonomy—requiring zero external database dependencies, zero third-party internet callbacks, and zero external runtime frameworks.

---

## 2. Core Architectural Capabilities

### 2.1 Direct I/O Kdouja PageStore & 66,048-Byte Sector Alignment
* **Direct Hardware Block I/O**: Eliminates host kernel page-cache double-buffering by enforcing unbuffered direct disk I/O (`O_DIRECT` with sector alignment on Linux, `FILE_FLAG_NO_BUFFERING` on Windows).
* **Deterministic Physical Page Geometry**: Enforces exact 66,048-byte physical storage chunks (512-byte cryptographic header + 64 KB sector-aligned payload) optimized for direct NVMe flash controller block cycles.
* **Embedded Kdouja LSM Engine**: High-throughput embedded Log-Structured Merge (LSM) key-value engine with Write-Ahead Logging (WAL) for sub-millisecond chunk lookup and direct memory allocation.
* **Non-Blocking Page Reclamation**: Native asynchronous support for `ReleasePage` and block compaction RPCs to dynamically eliminate storage fragmentation under sustained write saturation.

### 2.2 Medical-Reasoning Diagnostics & Multi-Subsystem Harvester
* **Continuous Hardware Probing**: High-frequency telemetry harvesters inspect CPU instruction counters, thermal registers, memory ECC bus errors, PCI Express lanes, storage controller queues, network link duplex, and NUMA node topology.
* **Subsystem Coverage**:
  * **Storage**: NVMe controller telemetry logs, SMART endurance percentages, media errors, wear-leveling indices, latency histograms, IOPS, and queue depth.
  * **Memory**: DIMM channel topology, hardware ECC errors, swap saturation, dirty page writeback pressure, and slab allocation footprints.
  * **Processor**: Per-core C-state and P-state distribution, thermal throttling triggers, AVX2 utilization, interrupt storms, and context switch velocity.
  * **Network**: Physical NIC ring buffer drops, PCIe FIFO overruns, ethtool hardware error counters, CRC checksum failures, and mTLS handshake overhead.
* **Diagnostic Noise Suppression**: Intelligent signal-denoising algorithms correlate raw telemetry anomalies across subsystems, suppressing transient spikes and de-escalating alarm fatigue.

### 2.3 Machine Learning Failure Forecasting & Proactive Evacuation
* **Statistical Reliability Analysis**: Autonomous on-node Weibull distribution modeling, Holt-Winters double exponential smoothing, and Ordinary Least Squares (OLS) degradation tracking.
* **Predictive Drive Evacuation**: Detects latent mechanical or NAND flash degradation weeks before total sector failure occurs. Upon crossing critical risk thresholds, Abodi automatically marks deteriorating drives with `AllowWrite = false` and signals the cluster coordinator to perform non-disruptive, proactive Cauchy shard evacuation.

### 2.4 Resilient Air-Gapped Outbox (SQLite WAL Engine)
* **Zero-Loss Telemetry Retention**: Embedded transactional SQLite write-ahead log (WAL) outbox safely persists metrics, audit trails, and heartbeat snapshots on local NVMe storage during network isolation or coordinator failovers.
* **Deterministic Monotonic Replay**: Automatic FIFO replay with backpressure throttling and strict local disk quota guards to ensure local drives never exhaust storage during prolonged partition events.

### 2.5 Zero-Trust Cryptographic Identity & mTLS Mesh
* **Dynamic Ephemeral Bootstrap**: Zero-touch node onboarding using single-use, cryptographically verified enrollment tokens (`ET1.<hex>`).
* **Hardware SPIFFE ID Attestation**: All intra-cluster RPC communication is mutual-TLS (mTLS) encrypted and verified against SPIFFE identities (`spiffe://rokka.cluster/node/{node-code}`).
* **Secure Keyring Protection**: Host cryptographic certificates and private keys are strictly guarded with POSIX `0700`/`0600` access boundaries and automated memory zeroization.

### 2.6 Multi-Sink Structured Serilog Observability
* **Multi-Sink Logging Fabric**: Out-of-the-box native streaming to structured `Console`, rolling hourly `File` archives (with 100 MB caps and retention controls), `Seq` event ingestors, and `Elasticsearch` time-series data streams (`logs-abodi-agent-{env}`).
* **Deep Correlation & Process Footprint**: Every log event and telemetry trace automatically carries `CorrelationId`, `TraceId`, `SpanId`, `WorkingSetBytes`, `ManagedMemoryBytes`, `ThreadCount`, `NodeUptimeSeconds`, and host OS environment identifiers.

---

## 3. Supported Container Tags & Architectures

| Tag | Target Architecture | Base OS | Description |
| :--- | :--- | :--- | :--- |
| **`v1.0.2`**, **`1.0.2`**, **`latest`** | `linux/amd64` (x86_64, AVX2) | Ubuntu 24.04 LTS Noble (`dotnet/aspnet:10.0`) | Official Production Release with embedded hardware diagnostic utilities (`smartmontools`, `nvme-cli`, `lm-sensors`, `iproute2`, `ethtool`). |

---

## 4. Quick Start Guide

### 4.1 Running with Docker CLI (Hardware Direct I/O Mode)

To enable physical NVMe inspection, SMART diagnostic polling, and direct sector block I/O, execute the container with the `SYS_RAWIO` capability and mount the target physical block device:

```bash
docker run -d \
  --name aarkam-abodi \
  --restart unless-stopped \
  --cap-add=SYS_RAWIO \
  --device=/dev/nvme0n1:/dev/nvme0n1:rwm \
  -v /var/lib/rokka/storage:/var/lib/rokka/storage \
  -v /var/lib/rokka/security:/var/lib/aarkam/security \
  -v /var/lib/rokka/outbox:/var/lib/aarkam/outbox \
  -v /var/log/rokka/abodi:/app/logs \
  -p 57775:57775 \
  -p 57776:57776 \
  -p 7776:7776 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e Node__NodeCode="STORAGE-NODE-01" \
  -e Node__ClusterCode="ROKKA-PROD-CLUSTER" \
  -e Rokka__CoordinatorUrl="https://coordinator.rokka.internal:57774" \
  -e Security__EnrollmentToken="ET1.0123456789ABCDEF0123456789ABCDEF" \
  aarkam/aarkam.abodi:v1.0.2
```

### 4.2 Running with Docker Compose (Recommended)

Create a production `docker-compose.yml`:

```yaml
version: '3.8'

services:
  abodi:
    image: aarkam/aarkam.abodi:v1.0.2
    container_name: abodi-storage-daemon
    restart: unless-stopped
    cap_add:
      - SYS_RAWIO
    devices:
      - /dev/nvme0n1:/dev/nvme0n1:rwm
      - /dev/nvme1n1:/dev/nvme1n1:rwm
    volumes:
      - /var/lib/rokka/storage:/var/lib/rokka/storage
      - /var/lib/rokka/security:/var/lib/aarkam/security
      - /var/lib/rokka/outbox:/var/lib/aarkam/outbox
      - /var/log/rokka/abodi:/app/logs
    ports:
      - "57775:57775"   # gRPC mTLS: Kdouja Direct PageStore Data Plane
      - "57776:57776"   # HTTPS mTLS: Node Telemetry & Anomaly Plane
      - "7776:7776"     # HTTP Cleartext: Local Host Health & Liveness Probe
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - Node__NodeCode=STORAGE-NODE-01
      - Node__RackId=RACK-04
      - Node__DataCenter=DC-RIYADH-01
      - Rokka__CoordinatorUrl=https://coordinator.rokka.internal:57774
      - Storage__PageStorePath=/var/lib/rokka/storage
      - Storage__DirectIOEnabled=true
      - Storage__SectorAlignmentBytes=66048
      - Serilog__MinimumLevel=Information
      - Serilog__WriteToConsole=true
      - Serilog__WriteToFile=true
      - Serilog__WriteToSeq=false
      - Serilog__WriteToElasticsearch=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:7776/api/v1/health/ping"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 10s
```

Run the service:
```bash
docker compose up -d
```

---

## 5. Configuration Reference

Abodi is configured via environment variables or JSON configuration overrides:

### 5.1 Identity & Coordinator Binding
| Variable | Default | Description |
| :--- | :--- | :--- |
| `Node__NodeCode` | *Required* | Unique alphanumeric sovereign identifier for this storage node host. |
| `Node__ClusterCode` | `ROKKA-DEFAULT` | Identifier of the parent Rokka sovereign cluster. |
| `Node__DataCenter` | `DC-DEFAULT` | Geographic or datacenter zone identifier. |
| `Node__RackId` | `RACK-01` | Physical rack cabinet location for fault domain topology. |
| `Rokka__CoordinatorUrl` | *Required* | Fully qualified URL of the central Rokka Coordinator service. |
| `Security__EnrollmentToken`| *Optional* | One-time bootstrap token (`ET1.<hex>`) used during initial node onboarding. |

### 5.2 Storage & Kdouja Direct I/O Engine
| Variable | Default | Description |
| :--- | :--- | :--- |
| `Storage__PageStorePath` | `/var/lib/rokka/storage` | Directory where raw page store files are allocated. |
| `Storage__DirectIOEnabled` | `true` | Enforces unbuffered direct disk I/O (`O_DIRECT`). |
| `Storage__SectorAlignmentBytes`| `66048` | Physical sector geometry (512-byte header + 64KB aligned payload). |
| `Storage__SyncWrites` | `true` | Enforces synchronous write-through commits to persistent media. |

### 5.3 Serilog Structured Logging & Telemetry Sinks
| Variable | Default | Description |
| :--- | :--- | :--- |
| `Serilog__MinimumLevel` | `Information` | Minimum logging threshold (`Verbose`, `Debug`, `Information`, `Warning`, `Error`). |
| `Serilog__WriteToConsole` | `true` | Enables structured JSON console streaming. |
| `Serilog__WriteToFile` | `true` | Enables hourly rolling file log rotation in `/app/logs`. |
| `Serilog__WriteToSeq` | `false` | Enables real-time log ingestion into an external Seq server. |
| `Serilog__SeqUrl` | `""` | Endpoint URL of the target Seq server (e.g. `http://seq.internal:5341`). |
| `Serilog__WriteToElasticsearch` | `false` | Enables high-throughput indexing into Elasticsearch data streams. |
| `Serilog__ElasticsearchUrl` | `""` | Target Elasticsearch endpoint (e.g. `https://es.internal:9200`). |

---

## 6. Network Ports & Protocols

| Port | Protocol | Binding | Security | Purpose |
| :---: | :---: | :---: | :---: | :--- |
| **`57775`** | gRPC / HTTP/2 | `0.0.0.0` | **mTLS (SPIFFE)** | Direct Kdouja chunk transport, page allocation, and Cauchy shard reads/writes. |
| **`57776`** | HTTPS / REST | `0.0.0.0` | **mTLS (SPIFFE)** | Node telemetry snapshots, hardware manifests, predictive alerts, and placement scoring. |
| **`7775`** | gRPC / HTTP/2 | `127.0.0.1` | Cleartext | Local intra-node high-speed RPC IPC communication. |
| **`7776`** | HTTP / REST | `127.0.0.1` | Cleartext | Local host readiness probe (`/api/v1/health/ping`) and daemon liveness telemetry. |

---

## 7. Storage Volumes & State Persistence

| Container Path | Host Path Recommendation | Purpose |
| :--- | :--- | :--- |
| `/var/lib/rokka/storage` | Dedicated NVMe partition / mount | Kdouja physical block page stores and direct I/O chunk files. |
| `/var/lib/aarkam/security` | Encrypted tmpfs or local partition (`chmod 0700`) | SPIFFE mTLS certificates, node identity keys, and enrollment secrets. |
| `/var/lib/aarkam/outbox` | Local persistent fast storage | SQLite WAL write-ahead offline buffer during coordinator partitions. |
| `/app/logs` | `/var/log/rokka/abodi` | Structured Serilog rolling audit archives. |

---

## 8. Health Probes & Monitoring

Abodi exposes a high-frequency, non-blocking health probe endpoint for container orchestrators (Docker, Kubernetes, Nomad, systemd):

```bash
# Check daemon health status
curl -s http://localhost:7776/api/v1/health/ping
```

**Sample JSON Response:**
```json
{
  "status": "Healthy",
  "nodeCode": "STORAGE-NODE-01",
  "version": "1.0.2",
  "uptimeSeconds": 86420,
  "healthScore": 0.985,
  "drives": [
    {
      "device": "/dev/nvme0n1",
      "status": "Optimal",
      "wearPercent": 2.1,
      "temperatureCelsius": 38.0,
      "allowWrite": true
    }
  ],
  "footprint": {
    "workingSetMB": 128.4,
    "managedMemoryMB": 42.1,
    "threadCount": 18
  }
}
```

---

## 9. Security, Compliance & Governance

* **Saudi NCA ECC-2:2024 & CSCC-1:2023 Compliant**: Engineered to satisfy stringent national cybersecurity authority requirements for sovereign cloud and critical infrastructure.
* **FIPS 140-3 Zero-Trust Cryptography**: Direct cryptographic validation for mutual TLS, key storage, and token validation.
* **100% Air-Gapped Operation**: Completely decoupled from public internet infrastructures; zero outbound callbacks or proprietary SaaS telemetry beacons.
* **Least Privilege Container Runtime**: Hardened base image running without unnecessary system packages; strict device isolation and granular capability management.

---

## 10. Commercial Support & Ecosystem

Abodi is an official core component of the **Aarkam Sovereign Data Fabric**.

* **Website**: [https://aarkam.io](https://aarkam.io)
* **GitHub Repository**: [https://github.com/aarkamio/Aarkam](https://github.com/aarkamio/Aarkam)
* **Docker Hub Registry**: [https://hub.docker.com/r/aarkam/aarkam.abodi](https://hub.docker.com/r/aarkam/aarkam.abodi)
* **Documentation**: [https://aarkam.wiki](https://aarkam.wiki)
* **Enterprise Licensing**: Proprietary Sovereign Commercial License — [Aarkam.IO Legal](mailto:contact@aarkam.io)

---

<div align="center">
<sub>Copyright &copy; 2026 Aarkam.IO. All rights reserved. Sovereign Cloud, Storage Center & Autonomous Substrate Infrastructure.</sub>
</div>
