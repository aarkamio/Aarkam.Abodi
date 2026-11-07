# Aarkam Sovereign Distributed Object & File Storage Platform (`Aarkam.IO`)
### High-Performance, Distributed, Air-Gapped Object Storage Infrastructure for Sovereign Clouds, Defense, Banking & AI Datacenters

[![Build Status](https://img.shields.io/badge/Build-Passing%20(1%2C300%2B%20Tests)-0F6C3D?style=for-the-badge&logo=dotnet)](https://github.com/melhelbawi/Aarkam.IO)
[![Test Suite](https://img.shields.io/badge/Tests-1%2C300%2B%20Automated%20Tests-0F6C3D?style=for-the-badge&logo=checkmarx)](docs/PRODUCTION_READINESS_REPORT.md)
[![Release Suite](https://img.shields.io/badge/Release-V--1.0.0--GA-0F6C3D?style=for-the-badge&logo=github)](Releases/)
[![Air-Gapped Certified](https://img.shields.io/badge/Air--Gapped-100%25%20Zero%20Telemetry-0F6C3D?style=for-the-badge)](https://aarkam.io/)
[![S3 Compatibility](https://img.shields.io/badge/S3%20API-SigV4%20Compliant-blue?style=for-the-badge&logo=amazons3)](docs/07_APPLICATION_SUPPORT_AND_S3_SDK_GUIDE.md)
[![Alternative](https://img.shields.io/badge/Alternative-MinIO%20%7C%20Ceph%20Replacement-orange?style=for-the-badge)](Releases/Rokka/V-1.0.0/INSTALLATION_GUIDE.md)
[![Durability](https://img.shields.io/badge/Durability-11%20Nines%20(99.999999999%25)-purple?style=for-the-badge)](docs/05_CTO_SOVEREIGN_ARCHITECTURE_AND_COMPLIANCE_SPEC.md)
[![Customer Portal](https://img.shields.io/badge/Customer%20Portal-aarkam.io-17251D?style=for-the-badge&logo=googlechrome)](https://aarkam.io/)

**Official Customer Licensing & Operations Portal (AarkamCP)**: [https://aarkam.io/](https://aarkam.io/)  
**Commercial License**: [Aarkam Commercial Enterprise Sovereign License (ASCEL-v1.0)](LICENSE)  
**Current Production GA Suite**: `V-1.0.0-GA`

---

## 📦 Production GA Distribution Suite

The Aarkam platform is decoupled into four modular, standalone, independently deployable software components located under [`Releases/`](Releases/):

| Architecture & Component | Role & Scope | Embedded High-Performance Engine | Standalone Release Artifacts |
| :--- | :--- | :--- | :--- |
| **Aarkam - SAT (Standalone Tier): Rokka**<br/>*(MinIO & Ceph Alternative)* | **Sovereign Distributed Consensus & High-Speed S3 Storage Substrate**<br/>Stateless Raft Quorum Coordinator, Consistent Hash Ring & High-Speed S3/gRPC Data Transit | **Ahmodi**: AVX-512 SIMD Vectorized Cauchy Reed-Solomon Erasure Coding (12.5 GB/s/core) | [Release Notes](Releases/Rokka/V-1.0.0/RELEASE_NOTES.md) • [Installation Guide](Releases/Rokka/V-1.0.0/INSTALLATION_GUIDE.md) • [Checksums](Releases/Rokka/V-1.0.0/SHA256SUMS.txt) |
| **Aarkam - SCT (Storage Centers Tier): AarkamIO** | **Sovereign Enterprise Cloud & Ingress Control Plane**<br/>Edge S3 REST Gateway, Web Admin Console, IAM RBAC & Multi-Tenant Namespace Isolation | ASP.NET Core 10 Web Engine & SixFM AI Storage Fabric | [Release Notes](Releases/AarkamIO/V-1.0.0/RELEASE_NOTES.md) • [Installation Guide](Releases/AarkamIO/V-1.0.0/INSTALLATION_GUIDE.md) • [Checksums](Releases/AarkamIO/V-1.0.0/SHA256SUMS.txt) |
| **Aarkam - SAT (Standalone Tier): Abodi** | **Autonomous Hardware Telemetry & Node Agent**<br/>Out-of-band kernel S.M.A.R.T. monitoring, NVMe flash wear profiling & ML failure forecasting | **Kdouja**: Unbuffered Direct I/O (`O_DIRECT`) Zero-Copy 66KB LSM Storage Engine | [Release Notes](Releases/Abodi/V-1.0.0/RELEASE_NOTES.md) • [Installation Guide](Releases/Abodi/V-1.0.0/INSTALLATION_GUIDE.md) • [Checksums](Releases/Abodi/V-1.0.0/SHA256SUMS.txt) |
| **Management: AM CLI** | **Aarkam Manager (`am` / `am.exe`) Operator Tool**<br/>Single-binary administrative CLI for cluster orchestration, disk evacuation & health automation | Native Core Diagnostics & Cluster Orchestrator | [Release Notes](Releases/Am-Cli/V-1.0.0/RELEASE_NOTES.md) • [Installation Guide](Releases/Am-Cli/V-1.0.0/INSTALLATION_GUIDE.md) • [Checksums](Releases/Am-Cli/V-1.0.0/SHA256SUMS.txt) |

---

## 1. Executive Summary & Sovereign Value Proposition

**Aarkam** is an autonomous, distributed, ultra-high-throughput object storage platform engineered specifically for mission-critical sovereign clouds, national defense installations, core banking networks, smart hospitals, and air-gapped enterprise datacenters. 

Operating with **zero external telemetry egress** and **zero internet runtime dependencies**, Aarkam eliminates reliance on foreign hyperscaler clouds (AWS S3, Google Cloud Storage, Microsoft Azure Blob) and overcomes the operational fragility, hardware waste, and licensing traps of legacy software-defined storage systems (**MinIO Enterprise**, **Ceph**, **Dell ECS**, **NetApp**).

### The Four Sovereign Value Pillars

```
  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                                   AARKAM SOVEREIGN PILLARS                                       │
  ├──────────────────────────────┬──────────────────────────────┬────────────────────────────────────┤
  │    1. DATA SOVEREIGNTY       │   2. 58.3% HARDWARE SAVINGS  │    3. DIRECT NVMe HARDWARE SPEED   │
  │  • 100% Air-Gapped Certified │  • Cauchy Reed-Solomon Math  │  • Kernel Page-Cache Bypass        │
  │  • Zero Telemetry Egress     │  • 1.25x - 1.37x raw footprint│  • In-process Kdouja LSM Engine   │
  │  • NCA ECC & SDAIA Compliant │  • Replaces 3x replication   │  • Zero Inode Exhaustion           │
  ├──────────────────────────────┴──────────────────────────────┴────────────────────────────────────┤
  │                            4. PREDICTIVE PROACTIVE SELF-HEALING                                  │
  │  • Out-of-band Abodi sidecar monitors NVMe flash wear, sector jitter & thermal drift             │
  │  • 72-hour machine-learning runway forecasting migrates data before hardware faults              │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Absolute Data Sovereignty & Zero Egress**:  
   Aarkam is designed from the silicon layer up to operate indefinitely inside fully isolated, dark-site facilities. Every software package is cryptographically signed, self-contained, and completely free of external dependencies. Compliance is pre-aligned with Saudi National Cybersecurity Authority (**NCA ECC-2:2024 / CSCC-1:2023**), Saudi Data & AI Authority (**SDAIA PDPL**), National Data Management Office (**NDMO**), and Saudi Central Bank (**SAMA**) cybersecurity frameworks.

2. **Mathematical Hardware Efficiency (Up to 58.3% Hardware Footprint Cut)**:  
   Traditional distributed storage platforms (Ceph, legacy clusters) rely on triple replication ($3\times$), demanding $300\text{ TB}$ of raw physical drive capacity to store $100\text{ TB}$ of usable data. Aarkam's embedded **Ahmodi** mathematical engine utilizes vectorized Cauchy Reed-Solomon erasure coding over Galois Field $\text{GF}(2^8)$. Storing $100\text{ TB}$ of usable data with Ahmodi `(8+3)` requires only $137.5\text{ TB}$ raw (72.7% storage efficiency), and Archive `(16+4)` requires only $125\text{ TB}$ raw (80% storage efficiency)—saving multi-million SAR/USD capital expenditures in drives, chassis, rack space, power, and cooling.

3. **Direct NVMe Hardware Saturation (Zero Inode Exhaustion)**:  
   Storing millions of discrete chunk files on conventional operating system filesystems (ext4, XFS, NTFS) leads to catastrophic inode exhaustion, metadata lock contention, and OS page cache double-buffering (the classic MinIO/Ceph bottleneck). Storage nodes in Aarkam bypass filesystem overhead by embedding **Kdouja**, an in-process log-structured merge-tree (LSM) persistence engine. Kdouja streams raw data chunks straight to NVMe media utilizing unbuffered Direct I/O (`O_DIRECT` on Linux, `FILE_FLAG_NO_BUFFERING` on Windows) with sector-aligned 66,048-byte physical blocks, completely bypassing the OS page cache.

4. **Autonomous Predictive Self-Healing (Zero 3 AM Emergency Panic)**:  
   Enterprise storage traditionally discovers disk degradation only after write timeouts occur, triggering aggressive foreground rebuild storms that crush cluster throughput. Aarkam's **Abodi** daemon continuously analyzes S.M.A.R.T. counters, media wear, read error rates, and kernel SCSI resets. When an anomalous runway (e.g., 72 hours) is forecasted by Abodi's ML models, Rokka gracefully fences the node and migrates surviving chunks in the background while the drive is still healthy, delivering continuous zero-downtime operations.

---

## 2. Aarkam - SAT (Standalone Tier): Rokka — The High-Throughput Sovereign Alternative to MinIO & Ceph

In addition to serving as the foundational storage substrate for the complete Aarkam Enterprise Cloud (**Aarkam - SCT: Storage Centers Tier**), **Rokka V-1.0.0-GA is engineered and packaged as Aarkam - SAT (Standalone Tier)** to be deployed completely STANDALONE as a modern, high-performance, drop-in replacement for **MinIO Enterprise** and **Ceph (RGW / RADOS)**.

```
                    ┌───────────────────────────────────────────────────────────────┐
                    │              AARKAM - SAT (STANDALONE TIER): ROKKA            │
                    │               Next-Gen Autonomous Object Substrate            │
                    └───────────────────────────────┬───────────────────────────────┘
                                             │
             ┌───────────────────────────────┴───────────────────────────────┐
             ▼                                                               ▼
   vs. MinIO Enterprise                                            vs. Ceph (RGW / RADOS)
   ────────────────────                                            ──────────────────────
   ❌ Restrictive AGPLv3 & capacity tax fees                       ❌ Staggering administrative complexity
   ❌ Filesystem-bound inode bottlenecks (ext4/XFS)                ❌ 3x replication wastes 200% storage
   ❌ Telemetry phone-home auditing risks                          ❌ Slow OSD peering storms & deep-scrub I/O hits
   ❌ Tail latency spikes on degraded drives                       ❌ High CPU Jerasure erasure coding overhead
   ────────────────────                                            ──────────────────────
   ✅ ASCEL Sovereign Commercial Freedom                           ✅ Zero-Ops: 2 compact native binaries
   ✅ Unbuffered NVMe Direct I/O (Kdouja Engine)                   ✅ 58.3% Raw Footprint Cut (Ahmodi SIMD RS)
   ✅ 100% Air-Gapped Zero-Egress Certified                        ✅ Sub-millisecond P99 via Speculative Hedged Reads
   ✅ Predictive 72h ML Disk Draining (Abodi)                      ✅ 12.5 GB/s per core AVX-512 Reconstruction
```

### Comprehensive Technical Comparison Matrix

| Architectural Dimension | Standalone Rokka V-1.0.0 | MinIO Enterprise | Ceph (Ceph S3 / RGW) |
| :--- | :--- | :--- | :--- |
| **Primary Architectural Role** | **Autonomous Sovereign S3 Storage Substrate** | S3-Compatible Object Store | Distributed Unified Storage Cluster |
| **Deployment Simplicity** | **Zero-Ops**: 2 self-contained native binaries (`rokka-coordinator` & `rokka-gateway`) | Moderate: 1 binary, but complex tenant/site orchestration | **High Complexity**: Demands OSDs, MONs, MGRs, MDSs, CRUSH maps & peering |
| **Licensing & Egress Model** | **ASCEL Sovereign License**: 100% air-gapped, zero telemetry, zero capacity audits | **Restrictive AGPLv3** or high-cost commercial capacity subscription tiers | Open-Source LGPL, but high enterprise support costs (Red Hat / IBM) |
| **Erasure Coding Math Kernel** | **Ahmodi**: SIMD AVX-512 & AVX2 Vectorized Cauchy Reed-Solomon over $\text{GF}(2^8)$ | Standard Reed-Solomon | Jerasure / CPU-intensive plugin |
| **Reconstruction Throughput** | **12.5 GB/s per CPU core** with inverted Cauchy submatrix caching | 1.8 – 3.2 GB/s per core | 0.8 – 2.1 GB/s per core |
| **Mathematical Storage Efficiency** | **72.7% (8+3) to 80.0% (16+4)** (Up to 58.3% Capex Savings) | ~66% (12+4 default) | Typically 3x Replication (33.3% efficiency / 300 TB raw) |
| **Underlying Persistence Engine** | **Kdouja Direct I/O (`O_DIRECT`)**: 66KB sector-aligned, zero page-cache pollution | Host filesystems (ext4/XFS): Prone to inode exhaustion & lock contention | BlueStore: Complex custom block allocator and RocksDB metadata layer |
| **Tail Latency Mitigation** | **Speculative Hedged Reads**: Automatically fires parity request upon jitter; flattens P99 | None: Tail latency is tied to the slowest individual drive | Severe latency spikes during OSD peering, deep scrubs, and recovery |
| **Drive Failure Handling** | **Proactive 72-Hour ML Runway (Abodi)**: Fences & drains drive before failure | Reactive: Rebuild storms begin only after drive failure timeouts occur | Reactive: Aggressive re-peering storms degrade cluster I/O throughput |
| **Client S3 Compatibility** | **100% AWS SigV4**: Drop-in for AWS CLI, MinIO `mc`, Boto3, Veeam, PyTorch | Full AWS S3 API | AWS S3 Compatible via Ceph RGW |
| **Memory Footprint** | Lightweight in-memory state; arena skip-lists (No GC pauses) | High Go runtime memory footprint under high concurrency | High RAM usage per OSD (4 GB to 8 GB RAM per physical drive) |
| **Deployment Target** | Bare-metal Linux/Windows, VM, Container, or Sovereign Air-Gap | Linux, Kubernetes, Docker | Bare-metal Linux or Rook Kubernetes Operator |

---

### Why Target Customers Choose Standalone Rokka

#### 1. For AI / Machine Learning & GPU Datacenters (PyTorch, TensorFlow, Slurm, Ray)
In large-scale AI distributed training clusters, hundreds of GPUs concurrently stream dataset shards and checkpoint multi-terabyte model weights via S3.
- **The MinIO / Ceph Failure Mode**: A single degraded drive in a 100-node Ceph or MinIO cluster experiences I/O jitter, delaying a data chunk. Because GPU synchronization barriers (NCCL AllReduce) wait for the slowest worker, the entire multi-million-dollar GPU cluster stalls waiting on that single disk.
- **The Rokka Solution**: Rokka's **Speculative Hedged Reads** detect jitter within milliseconds and immediately dispatch a speculative request to a Cauchy parity block. Whichever first 8 blocks return satisfy the read immediately, completely flattening P99 tail latency and keeping GPU compute pipelines at 100% saturation.

#### 2. For Core Banking & National Sovereign Clouds (SAMA, NCA ECC, NDMO, SDAIA)
Financial institutions and sovereign government clouds are mandated by cybersecurity regulations to eliminate foreign cloud egress and enforce total cryptographic data residency.
- **The MinIO Risk**: MinIO's transition to AGPLv3 and proprietary commercial licensing introduces compliance friction and telemetry verification risks.
- **The Rokka Solution**: Standalone Rokka is certified **100% air-gapped with zero telemetry egress**. It operates indefinitely in dark-site datacenters without ever connecting to an external endpoint, validated by cryptographic hardware fingerprint binding (`ARK-FP-...`).

#### 3. For Datacenter Infrastructure Architects & Storage Engineers
Datacenter operators managing petabyte-to-exascale storage infrastructure face ballooning power, cooling, and chassis procurement costs.
- **The Ceph Dilemma**: Maintaining Ceph clusters requires dedicated specialized engineering teams to troubleshoot peering storms, OSD memory bloat, and CRUSH map rebalancing. Default 3x replication wastes $200\text{ TB}$ of drive capacity for every $100\text{ TB}$ of usable storage.
- **The Rokka Solution**: Standalone Rokka delivers **58.3% physical footprint savings** via Ahmodi Archive `(16+4)` Cauchy Reed-Solomon math while running as two self-contained native binaries with zero external cluster dependencies.

---

### Quickstart: Deploy Standalone Rokka in Under 2 Minutes

Deploying Standalone Rokka requires no external databases, no ZooKeeper/Consul clusters, and no kernel modules.

#### Step 1: Unpack and Launch Daemons
```bash
# 1. Extract the standalone release package
mkdir -p /opt/rokka
unzip Releases/Rokka/V-1.0.0/rokka-v1.0.0-linux-x64.zip -d /opt/rokka
cd /opt/rokka

# 2. Launch Rokka Quorum Consensus Coordinator (Ports 7774 / 57774)
./rokka-coordinator &

# 3. Launch Rokka High-Throughput S3 REST Gateway (Ports 7772 / 57772)
./rokka-gateway &

# 4. On storage nodes: Launch Abodi (Kdouja Direct I/O PageStore - Ports 7775 / 57776)
cd /opt/abodi
./Abodi &
```

#### Step 2: Connect with MinIO Client (`mc`)
Rokka is a 100% drop-in replacement for MinIO. Your existing MinIO tooling works immediately:

```bash
# Configure standard MinIO mc alias pointing to Rokka S3 Gateway
mc alias set rokkastore http://localhost:7772 rokka_admin 0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF

# Create a bucket
mc mb rokkastore/ai-training-dataset

# Stream a multi-GB model weights payload directly into Rokka
mc cp --parallel 8 llama3-70b.safetensors rokkastore/ai-training-dataset/

# Verify bucket inventory
mc ls rokkastore/ai-training-dataset/
```

#### Step 3: Connect with AWS CLI
```bash
export AWS_ACCESS_KEY_ID="rokka_admin"
export AWS_SECRET_ACCESS_KEY="0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
export AWS_ENDPOINT_URL="http://localhost:7772"

aws --endpoint-url $AWS_ENDPOINT_URL s3 ls
```

---

## 3. Sovereign Production Network Architecture & Port Specification

> [!IMPORTANT]
> **Why Port 5001 is NOT Suited for Sovereign Production**:  
> In generic Microsoft ASP.NET Core developer templates, ports `5000` (HTTP) and `5001` (HTTPS) are default local loopback bindings. In enterprise and dark-site sovereign clouds, standardizing on dev ports creates severe security vulnerabilities, conflicts with existing host services (such as macOS/Linux media services and bastion local proxies), and violates network isolation policies.  
>  
> The Aarkam platform enforces a **deterministic, segregated port taxonomy**:
> - **Ingress / Control Services**: Dedicated `777x` series for cleartext/internal HTTP and `5777x` series for TLS 1.3 / mTLS HTTPS.
> - **Control Plane (AarkamIO)**: Binds to **`57771` (HTTPS)** and **`7771` (HTTP Ingress)**.
> - **S3 REST API Gateway (Rokka Gateway)**: Binds to **`57772` (HTTPS)** and **`7772` (HTTP)**.
> - **Quorum Consensus & Placement (Rokka Coordinator)**: Binds to **`57774` (HTTPS/mTLS)** and **`7774` (HTTP/2 gRPC)**.
> - **Kdouja Direct I/O Chunk Storage Fabric (Abodi)**: Binds to **`57775` (gRPC mTLS)** and **`7775` (gRPC Local)**.
> - **Node Diagnostics & Predictive SMART Telemetry (Abodi)**: Binds to **`57776` (HTTPS REST mTLS)** and **`7776` (HTTP REST)**.

### Master Network Port Matrix

| Port | Protocol | Binding Direction | Component | Role & Scope | Security & Cryptography |
| :---: | :---: | :---: | :--- | :--- | :--- |
| **`57771`** | HTTPS / TLS 1.3 | Inbound | **AarkamIO** | Web Management Console & Genesis Ceremony Wizard (`/genesis`) | TLS 1.3 / AES-256-GCM / RSA-4096-PSS |
| **`7771`** | HTTP | Inbound | **AarkamIO** | Management Web Ingress (Internal redirects to `57771`) | Cleartext HTTP (Redirect Only) |
| **`57772`** | HTTPS / TLS 1.3 | Inbound | **Rokka Gateway** | Production S3 REST API Gateway (SigV4) | AWS SigV4 HMAC-SHA256 / TLS 1.3 |
| **`7772`** | HTTP | Inbound | **Rokka Gateway** | High-Throughput Internal VPC S3 REST API Gateway | AWS SigV4 HMAC-SHA256 / Cleartext |
| **`57774`** | HTTPS / mTLS | Bi-directional | **Rokka Coordinator** | Raft MON Consensus, Placement Engine & Secret KV Store | Mutual TLS / HTTP/2 gRPC / Token Auth |
| **`7774`** | HTTP/2 gRPC | Internal Fabric | **Rokka Coordinator** | Cluster Epoch Sync, Leader Election & Inter-Node Monit | Internal gRPC RPC Mesh |
| **`57775`** | gRPC (mTLS) | Storage Mesh | **Abodi (Kdouja)** | Sector-Aligned (66KB) Direct I/O Chunk Data Streaming | Mutual TLS / Zero-Copy Direct I/O |
| **`7775`** | gRPC | Intra-Node | **Abodi (Kdouja)** | Local Intra-Node Direct I/O PageStore Transport | Local High-Speed IPC / gRPC |
| **`57776`** | HTTPS / REST | Inbound / Peer | **Abodi Agent** | Node Diagnostics, S.M.A.R.T. Profiling & Wear Telemetry | Mutual TLS / REST JSON API |
| **`7776`** | HTTP / REST | Localhost | **Abodi Agent** | Local Node Health Probes & Liveness Checkers | Cleartext JSON (`127.0.0.1`) |
| **`9090`** | TCP | Inbound | **All Nodes** | Prometheus Metrics Scrape Endpoint (`/metrics`) | Bearer Token Authenticated HTTP |

---

## 4. The Production Tier Architecture: Aarkam - SCT & Aarkam - SAT Explained Deeply

Aarkam decomposes the storage and data management stack into two strictly segregated architectural tiers—**Aarkam - SCT (Storage Centers Tier)** and **Aarkam - SAT (Standalone Tier)**—cleanly isolating client ingress and security policy from the physical consensus and storage fabric:

```mermaid
flowchart TD
    subgraph ClientPlane["Client Workload & Application Perimeter"]
        App1["Enterprise Applications<br/>(AWS SDKs, Boto3, Go, Java, C#)"]
        App2["Data Science & AI Pipelines<br/>(PyTorch, TensorFlow, Spark, Slurm)"]
        App3["Backup & Archive Agents<br/>(Veeam, Commvault, Kasten)"]
        AmCli["Operator Workstation<br/>Aarkam Manager (am / am.exe)"]
    end

    subgraph Tier2["AARKAM - SCT (STORAGE CENTERS TIER): SOVEREIGN ENTERPRISE CLOUD (AarkamIO)"]
        direction TB
        WebConsole["AarkamIO Web Management Console<br/>• Real-time Telemetry Dashboard & Quotas<br/>• Sovereign Genesis Ceremony Wizard (/genesis)<br/>• Port 57771 (HTTPS) / Port 7771 (HTTP)"]
        
        subgraph Tier2Control["Security, Management & AI Subsystems"]
            IAM["Sovereign IAM & RBAC Engine<br/>• OpenID Connect & Local Identity<br/>• Nafath National SSO Integration<br/>• Cryptographic Tenant Isolation"]
            SixFM["SixFM AI Sovereign Engine<br/>• Local SLM Smart File Search<br/>• Vector Embeddings (Zero Egress)<br/>• Arabic & English Semantic Query"]
            HSM["HSM Key Custody Engine<br/>• KMIP / PKCS#11 Dedicated HSM<br/>• AES-256-GCM Envelope Encryption"]
            Hangfire["Hangfire Distributed Engine<br/>• Asynchronous Telemetry Audits<br/>• Background Shard Rebalancing"]
        end
    end

    subgraph Tier1["AARKAM - SAT (STANDALONE TIER): PHYSICAL STORAGE FABRIC & DATA PLANE (Rokka + Abodi)"]
        direction TB
        Gateway["Rokka Edge S3 REST Gateway (rokka-gateway)<br/>• MinIO / Ceph High-Speed Alternative<br/>• AWS SigV4 Auth (AWS4-HMAC-SHA256)<br/>• Port 57772 (HTTPS) / Port 7772 (HTTP)<br/>• S3 API (Multipart, Tagging, Lifecycle, WORM Object Lock)"]

        subgraph QuorumConsensus["Consensus & Topology Subsystem (Rokka Coordinator)"]
            Rokka1["Rokka Quorum Leader 1<br/>(Raft State Machine :57774 / :7774)"]
            Rokka2["Rokka Quorum Leader 2<br/>(Raft State Machine :57774 / :7774)"]
            Rokka3["Rokka Quorum Leader 3<br/>(Raft State Machine :57774 / :7774)"]
            AhmodiEngine["Embedded Ahmodi Mathematical Engine<br/>• Cauchy Reed-Solomon Galois Field GF(2⁸)<br/>• AVX-512 & AVX2 SIMD Vectorization (12.5 GB/s/core)<br/>• Profiles: (4+2), (8+3), (8+4), (16+4)"]
        end

        subgraph PhysicalStorageFleet["Physical Storage Node Tier (Abodi Agents)"]
            subgraph Node1["Physical Storage Node 01"]
                Abodi1["Abodi Agent (:57776 REST / :57775 gRPC)<br/>• Kernel S.M.A.R.T. Watchdog<br/>• ML Failure Runway (72h Forecast)"]
                Kdouja1["Embedded Kdouja LSM Engine<br/>• Direct I/O (O_DIRECT) NVMe Bypass<br/>• 66KB Physical Sector Alignment<br/>• Unmanaged Arena Pools (No GC)"]
                Disks1["Physical NVMe / SAS Storage Pool"]
            end

            subgraph Node2["Physical Storage Node 02"]
                Abodi2["Abodi Agent (:57776 REST / :57775 gRPC)"]
                Kdouja2["Embedded Kdouja LSM Engine"]
                Disks2["Physical NVMe / SAS Storage Pool"]
            end

            subgraph NodeN["Physical Storage Node N (Up to 256 Nodes)"]
                AbodiN["Abodi Agent (:57776 REST / :57775 gRPC)"]
                KdoujaN["Embedded Kdouja LSM Engine"]
                DisksN["Physical NVMe / SAS Storage Pool"]
            end
        end
    end

    subgraph CustomerPortal["AARKAM CUSTOMER PORTAL & LICENSING (AarkamCP)"]
        Portal["Aarkam Official Portal<br/>https://aarkam.io/<br/>• Subscriptions & Entitlements<br/>• Multi-Factor Hardware Profiler Binding<br/>• Sovereign Genesis Ceremony (.arkbundle)"]
    end

    %% Ingress and Data Flow
    App1 -->|"S3 REST API (SigV4) :57772"| Gateway
    App2 -->|"S3 REST API (SigV4) :57772"| Gateway
    App3 -->|"S3 REST API (SigV4) :57772"| Gateway
    AmCli -->|"Admin HTTPS / REST :57771"| WebConsole
    AmCli -.->|"Direct Coordinator API :57774"| Rokka1
    AmCli -.->|"Direct Node Diagnostics :57776"| Abodi1

    WebConsole <-->|"Control & Secret Sync"| Tier2Control
    WebConsole <-->|"Topology & Partition Lookup"| Rokka1
    Gateway <-->|"Rendezvous HRW Shard Map"| Rokka1
    Gateway <-->|"Direct Chunk Streaming :57775"| Node1
    Gateway <-->|"Direct Chunk Streaming :57775"| Node2
    Gateway <-->|"Direct Chunk Streaming :57775"| NodeN

    Rokka1 <--> Rokka2
    Rokka2 <--> Rokka3
    Rokka1 --- AhmodiEngine

    Abodi1 -->|"Health Heartbeats & Telemetry :57774"| Rokka1
    Abodi2 -->|"Health Heartbeats & Telemetry :57774"| Rokka1
    AbodiN -->|"Health Heartbeats & Telemetry :57774"| Rokka1

    Kdouja1 --- Disks1
    Kdouja2 --- Disks2
    KdoujaN --- DisksN

    %% Offline Activation Flow
    WebConsole -.->|"1. Display Hardware Fingerprint (ARK-FP-...)"| AmCli
    AmCli -.->|"2. Bind Fingerprint on Portal (Out-of-Band)"| Portal
    Portal -.->|"3. Mint Cryptographically Signed Genesis Bundle (.arkbundle)"| AmCli
    AmCli -.->|"4. Offline Genesis Sealing (/genesis)"| WebConsole
```

---

### Detailed Tier Breakdown: Aarkam - SCT & Aarkam - SAT

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│        AARKAM - SCT (STORAGE CENTERS TIER): SOVEREIGN ENTERPRISE CLOUD, INGRESS & CONTROL PLANE        │
├────────────────────────────────┬───────────────────────────────────────────────────────────────────────┤
│ Component                      │ AarkamIO (`Releases/AarkamIO/V-1.0.0/`)                                │
│ Primary Role                   │ Perimeter Web Console, Sovereign IAM, Genesis Wizard & Orchestration  │
│ Target Deployment Scope        │ Dedicated Management Hosts or Bastion Frontends fronting the cluster   │
│ Management Web Interface       │ Port 57771 (HTTPS / TLS 1.3) • Port 7771 (HTTP Redirect)              │
│ Target Binaries                │ `aarkamio` (Linux) / `Aarkam.exe` (Windows Server)                    │
├────────────────────────────────┴───────────────────────────────────────────────────────────────────────┤
│ Core Architectural Subsystems:                                                                         │
│  1. Sovereign Web Console & Dashboard: Real-time cluster topology, health scores & telemetry charts.   │
│  2. Genesis Ceremony Activation Wizard: Sealed offline air-gapped bootstrapping endpoint (/genesis).   │
│  3. SixFM AI Sovereign Storage Fabric: Embedded Small Language Model (SLM) vector search engine that   │
│     indexes document semantics locally in memory with zero external API calls or data egress.          │
│  4. HSM Key Custody: Client envelope encryption via AES-256-GCM backed by hardware HSM (KMIP/PKCS#11). │
│  5. Sovereign Identity (IAM): Multi-tenant namespaces, OpenID Connect, Nafath SSO, and RBAC policies. │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│        AARKAM - SAT (STANDALONE TIER): PHYSICAL STORAGE FABRIC & DATA PLANE (STANDALONE SUBSTRATE)     │
├────────────────────────────────┬───────────────────────────────────────────────────────────────────────┤
│ Components                     │ Rokka (`Releases/Rokka/V-1.0.0/`) & Abodi (`Releases/Abodi/V-1.0.0/`)  │
│ Primary Role                   │ S3 REST Gateway, Distributed Consensus, Cauchy RS & NVMe Direct I/O   │
│ Drop-In Alternative To         │ MinIO Enterprise & Ceph (RGW / RADOS)                                 │
│ Target Deployment Scope        │ Standalone S3 Cluster OR as Aarkam - SAT Substrate under Aarkam - SCT │
│ S3 Client Ingress Ports        │ Port 57772 (HTTPS S3 REST SigV4) • Port 7772 (HTTP S3 REST SigV4)     │
│ Cluster Consensus Ports        │ Port 57774 (HTTPS / mTLS) • Port 7774 (HTTP/2 gRPC Raft Mesh)          │
│ Storage Node Chunk Transit     │ Port 57775 (gRPC mTLS) • Port 7775 (Local gRPC)                        │
│ Node Telemetry & Diagnostics   │ Port 57776 (HTTPS REST mTLS) • Port 7776 (Local REST)                 │
│ Target Binaries                │ `rokka-coordinator`, `rokka-gateway`, `Abodi`                         │
├────────────────────────────────┴───────────────────────────────────────────────────────────────────────┤
│ Core Architectural Subsystems:                                                                         │
│  1. Rokka Consensus Coordinator: Stateless Raft distributed state machine governing cluster epochs,   │
│     partition distribution, Rendezvous consistent hash rings, and active node membership.              │
│  2. Embedded Ahmodi Engine: SIMD AVX-512 & AVX2 vectorized Cauchy Reed-Solomon math over GF(2⁸).       │
│     Computes Cauchy generator matrices where every sub-matrix is non-singular, enabling instant        │
│     Gaussian elimination inversion and 12.5 GB/s/core throughput. Profiles: (4+2), (8+3), (16+4).     │
│  3. Speculative Hedged Reads: Eliminates tail latency. For an (8+3) object, Rokka requests 8 data      │
│     chunks. If any node exhibits I/O jitter, a speculative request is instantly fired to a parity node.│
│     The first 8 chunks to return decode the object, completely flattening P99 tail latency spikes.     │
│  4. Abodi Hardware Sentinel: Autonomous out-of-band daemon polling kernel sysfs/WMI S.M.A.R.T. counters│
│     (Reallocated sectors ID 05, Pending sectors ID 197, NVMe wear %, SCSI bus resets) with 72h ML      │
│     failure forecasting. Degraded drives are drained gracefully without taking the cluster offline.    │
│  5. Embedded Kdouja LSM Engine: In-process Direct I/O (`O_DIRECT`) NVMe bypass writing sector-aligned │
│     66,048-byte physical blocks into multi-GB append-only container segments with zero GC overhead.    │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Production Deployment Architectures & Sizing Matrix

Aarkam is officially validated and certified across two enterprise-grade production architectures:

| Architectural Metric | Architecture 1: Enterprise Sovereign Tier | Architecture 2: GovCloud Critical Sovereign Tier |
| :--- | :--- | :--- |
| **Target Workloads** | Core Banking, PACS Hospital Imaging, Telemetry Lakes, AI Pipelines | Public Sector Ministries, National Defense, Central Bank Core Systems |
| **Regulatory Compliance** | ISO 27001, SOC 2 Type II, Local Banking PCI-DSS | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, SDAIA PDPL, NDMO, SAMA Cyber |
| **Rokka Consensus Quorum** | **3 Quorum Leaders** (Raft Consensus on Port `57774`) | **5 Geo-Distributed Quorum Leaders** (Active-Active Multi-DC) |
| **Physical Storage Nodes** | **8 to 32 Storage Hosts** (Abodi on Port `57775` / `57776`) | **32 to 256+ High-Density Storage Hosts** |
| **Physical Storage Drives** | Up to 256 NVMe / SAS Enterprise SSDs | 1,024 to 4,096+ NVMe / SAS 4Kn Drives |
| **Usable Storage Capacity** | **50 TB to 500 TB** (Scalable to Multi-PB) | **2 Petabytes to Exascale** |
| **Erasure Coding Profile** | **Ahmodi `(8+3)` & Cauchy RS `(8+4)`** | **Ahmodi Archive `(16+4)` & Cauchy RS `(8+4)`** |
| **Mathematical Storage Efficiency** | **72.7% Efficiency** (54.2% Raw Footprint Savings) | **80.0% Efficiency** (58.3% Raw Footprint Savings) |
| **Node Failure Tolerance** | Survives simultaneous loss of **3 complete nodes** | Survives simultaneous loss of **4 complete nodes / datacenters** |
| **Durability Math** | **$99.999999999\%$** (Eleven 9s) | **$99.999999999999\%$** (Fourteen 9s) |
| **AI Semantic Search** | **SixFM SLM Engine Included** (Local Vectors) | **SixFM Full Semantic Fabric with Native Arabic & English NLP** |
| **Identity & Authentication** | OpenID Connect, LDAP, Active Directory, SigV4 | **National SSO & Nafath IAM Integration**, PKCS#11 Smartcards |
| **Geo-Replication** | Dual-Datacenter Active-Active Sync | **Tri-Region Geo-Mesh** (Riyadh / Jeddah / Dammam) |
| **High Availability SLA** | **$99.99\%$ Guaranteed Uptime** | **$99.999\%$ Guaranteed Uptime** with 15-minute SRE response |

---

## 6. End-to-End Activation Through Aarkam Customer Portal (AarkamCP)

In adherence to sovereign defense standards, **license minting tooling is strictly quarantined to Aarkam HQ**. Enterprise license certificates and Genesis ceremony bundles (`.arkbundle`) are generated exclusively via the official **Aarkam Customer Portal** at **[https://aarkam.io/](https://aarkam.io/)**.

Deploying an Aarkam cluster follows a zero-trust, 5-stage sovereign activation ceremony:

```
  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                           SOVEREIGN AIR-GAPPED ACTIVATION CEREMONY                               │
  ├──────────────────────────────────────────────────────────────────────────────────────────────────┤
  │                                                                                                  │
  │   [On-Premises Datacenter]                   [Air-Gap Boundary]         [Official Portal]        │
  │                                                                        https://aarkam.io/        │
  │                                                                                                  │
  │   1. Deploy Cluster Services                                                                     │
  │      (AarkamIO :57771, Rokka :57774, Abodi :57776)                                               │
  │                 │                                                                                │
  │                 ▼                                                                                │
  │   2. Extract Hardware Fingerprint                                                                │
  │      ARK-FP-A7B2C3D4-E5F6G7H8-...                                                                │
  │                 │                                                                                │
  │                 └───────────────────────── (Secure Media) ──────────────► 3. Register & Bind    │
  │                                                                               Cluster on AarkamCP│
  │                                                                               (Select Tier & Ops)│
  │                                                                                      │           │
  │                                                                                      ▼           │
  │   5. Genesis Sealing Ceremony ◄─────────── (Secure Media) ─────────────── 4. Mint Sealed Genesis │
  │      Cluster locks into Sovereign                                            Bundle (.arkbundle) │
  │      Mode (IsBootstrapped = true)                                                                │
  │      Zero Ongoing Internet Needed                                                                │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Stage 6.1: Deploy Storage Services in Un-Bootstrapped State

Deploy the binaries from `Releases/` onto your nodes. The cluster starts in an unsealed bootstrap mode (`IsBootstrapped = false`), exposing only the genesis administrative endpoints:

```bash
# 1. On EVERY Physical Storage Node: Launch Abodi (Storage Daemon & Kdouja Engine)
cd Releases/Abodi/V-1.0.0/linux
./Abodi
# Binds to https://0.0.0.0:57776 (REST Telemetry) and https://0.0.0.0:57775 (gRPC Data Fabric)

# 2. On Quorum Coordinator Nodes (3 or 5 nodes): Launch Rokka Coordinator
cd Releases/Rokka/V-1.0.0/linux
./rokka-coordinator
# Binds to https://0.0.0.0:57774 (HTTPS / mTLS) and http://0.0.0.0:7774 (HTTP/2 gRPC Raft)

# 3. On S3 Ingress Gateway Nodes: Launch Rokka S3 Gateway
cd Releases/Rokka/V-1.0.0/linux
./rokka-gateway
# Binds to https://0.0.0.0:57772 (HTTPS S3 REST) and http://0.0.0.0:7772 (HTTP S3 REST)

# 4. On Gateway / Management Nodes: Launch AarkamIO (Enterprise Control Plane & Web Console)
cd Releases/AarkamIO/V-1.0.0/linux
./aarkamio --urls "https://0.0.0.0:57771;http://0.0.0.0:7771"
# Binds to https://0.0.0.0:57771 (HTTPS Web Console & Genesis Wizard)
```

### Stage 6.2: Extract the Deterministic Multi-Factor Hardware Fingerprint

The Aarkam platform embeds an immutable, tamper-resistant `ClusterHardwareProfiler`. It interrogates the physical silicon layer and generates a cryptographic hardware fingerprint across five deterministic factors:
- **Factor 1**: Machine Hostname, Logical Processor Count, and CPU Architecture.
- **Factor 2**: Immutable OS Host UUID (`/etc/machine-id` on Linux, Registry `MachineGuid` on Windows).
- **Factor 3**: Primary Physical Network Interface Controller (NIC) MAC Address.
- **Factor 4**: Derivation via HMAC-SHA256 keyed with the official binary Aarkam Root Public Key.

To view your cluster fingerprint, navigate your browser to the secure Genesis endpoint:
```text
https://<gateway-node-ip>:57771/genesis
```
*Or query via the standalone operator CLI:*
```bash
cd Releases/Am-Cli/V-1.0.0/linux
./am cluster fingerprint
# Output: ARK-FP-4F8A91C2-E6B3D107-88C49F01
```

### Stage 6.3: Register Cluster & Bind Subscription on AarkamCP ([https://aarkam.io/](https://aarkam.io/))

1. Open your browser and navigate to the official portal: **[https://aarkam.io/](https://aarkam.io/)**.
2. Log in with your enterprise credentials and navigate to:
   ```text
   AarkamCP Portal -> Administration -> Current Subscription -> Cluster Hardware Bindings
   ```
3. Select your contracted production tier (**Enterprise Sovereign** or **GovCloud Critical Sovereign**).
4. Enter your designated **Cluster Code** (e.g., `ARK-PROD-RYD-01`) and paste the **Cluster Hardware Fingerprint** (`ARK-FP-...`).
5. Provision your cryptographically injected enterprise operators (usernames, roles, and salted password hashes). These credentials will be sealed directly into the cryptographic envelope.

### Stage 6.4: Mint the Sovereign Genesis Ceremony Bundle (`.arkbundle`)

Click **Generate Sovereign Genesis Bundle** in the portal. AarkamCP's secure licensing engine executes the following cryptographic operations:
1. Constructs a strongly typed `SovereignLicensePayload` incorporating your tier quotas, authorized nodes, and enabled modules (`AhmodiErasureCoding`, `SixFMVectorSearch`, `DedicatedHsmIsolation`, `NafathIAMIntegration`, etc.).
2. Embeds the injected operator security claims directly into the payload.
3. Cryptographically signs the envelope using RSA-4096 / ECDSA P-384 with the **Aarkam Sovereign Root CA** private key.
4. Generates and downloads the sealed file:
   ```text
   Aarkam-Genesis-ARK-PROD-RYD-01.arkbundle
   ```

### Stage 6.5: Perform the Air-Gapped Genesis Sealing Ceremony

Transfer the `.arkbundle` file into your air-gapped datacenter via approved secure physical media (e.g., hardware-encrypted optical media or defense-approved USB data diodes):

1. Access the web console at `https://<gateway-node-ip>:57771/genesis`.
2. Upload `Aarkam-Genesis-ARK-PROD-RYD-01.arkbundle`.
3. Enter your root administrator passphrase.
4. **Autonomous Cryptographic Verification**:
   - AarkamIO validates the bundle's digital signature against the hardcoded Sovereign Root CA public key.
   - It re-computes the local hardware profile to ensure exact fingerprint matching.
   - It deploys the sealed operator claims into the Kdouja LSM-tree metadata store via Rokka.
   - It transitions the cluster state to `IsBootstrapped = true`, locks all genesis endpoints permanently, and redirects to the secure login interface at `/login`.

> [!IMPORTANT]
> **Zero Egress Verification Guarantee**:  
> Once the `.arkbundle` is sealed, **the cluster is 100% self-sufficient**. It will never attempt an outbound connection to `https://aarkam.io/` or any external IP address. All licensing quotas, cryptographic time envelopes, and feature flags are audited locally inside the sovereign perimeter.

---

## 7. End-to-End Zero-Allocation Data Path

Aarkam is architected to eliminate CPU cache thrashing and memory allocations across the complete read and write lifecycle:

```
  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                            END-TO-END ZERO-ALLOCATION WRITE PATH                                 │
  ├──────────────┬──────────────────┬──────────────────┬──────────────────────┬──────────────────────┤
  │ 1. S3 INGEST │ 2. ENVELOPE CRYPT│ 3. CAUCHY MATRIX │ 4. PARALLEL TRANSIT  │ 5. DIRECT NVMe WRITE │
  │ AWS SigV4    │ AES-256-GCM      │ AVX-512 SIMD     │ Parallel gRPC mTLS   │ Kdouja Direct I/O    │
  │ Port 7772 /  │ Client/HSM Key   │ GF(2⁸) Kernel    │ Multi-Node Chunk     │ Unbuffered (O_DIRECT)│
  │ Port 57772   │ In-Memory Cipher │ Ahmodi Parity    │ Streaming (:57775)   │ Bypass OS Page Cache │
  └──────────────┴──────────────────┴──────────────────┴──────────────────────┴──────────────────────┘
```

1. **Ingress & Authentication**: The client application issues an `S3 PUT` request to the Rokka Gateway (`Port 57772 HTTPS` or `Port 7772 HTTP`). The gateway validates the AWS SigV4 signature (`AWS4-HMAC-SHA256`) and routes the incoming payload into pre-allocated native memory spans.
2. **Client Envelope Encryption**: If bucket encryption is enabled, the stream is encrypted on the fly via hardware-accelerated AES-256-GCM using keys managed in an on-premises HSM.
3. **Ahmodi Cauchy Reed-Solomon Vector Kernel**: The payload is partitioned into $K$ data blocks. Ahmodi applies an AVX-512 vectorized Cauchy generator matrix over $\text{GF}(2^8)$, generating $M$ parity blocks simultaneously at **12.5 GB/s per CPU core**.
4. **Non-Blocking gRPC Transit**: The $K+M$ chunks are concurrently dispatched across the internal cluster fabric to designated storage nodes over high-speed mutual TLS (mTLS) streams to Abodi on **Port `57775`**.
5. **Kdouja Direct I/O Persistence**: Each storage node receives its chunk and writes it directly to NVMe flash in sector-aligned 66,048-byte physical blocks using unbuffered Direct I/O (`O_DIRECT`), committing to the synchronous Write-Ahead Log (WAL) and memory skip-list without kernel page cache intervention.

---

## 8. Using the Aarkam Manager (AM) CLI (`am` / `am.exe`)

The standalone CLI binary `am` (located in [`Releases/Am-Cli/V-1.0.0/`](Releases/Am-Cli/V-1.0.0/)) provides single-binary, deterministic command-line administration for SREs and automation scripts:

```bash
cd Releases/Am-Cli/V-1.0.0/linux

# 1. Inspect live cluster consensus, epoch state, and active leaders (queries Coordinator :57774)
./am cluster status --watch 1s

# 2. Inspect physical hardware health and S.M.A.R.T. status across all storage nodes
./am disk list

# 3. View Abodi ML failure runway score for a specific NVMe drive (queries Abodi :57776)
./am abodi score --device /dev/nvme0n1 --format json

# 4. Gracefully drain a degraded disk prior to physical hot-swap
./am disk drain /dev/nvme2n1 --reason "Abodi Predictive S.M.A.R.T. Alert"

# 5. Evacuate an entire storage node for scheduled hardware maintenance
./am node evacuate storage-node-04 --reason "DIMM replacement" --yes

# 6. Run on-host SIMD Galois Field AVX-512 performance benchmark
./am benchmark simd --profile 8+3
```

---

## 9. Application Integration & S3 SDK Verification

Aarkam and Standalone Rokka are 100% drop-in replacements for AWS S3 and MinIO. Existing enterprise software, backup platforms, and developer libraries run without code modifications:

### AWS CLI (Standard S3 Client)
```bash
# Configure standard S3 credentials pointing to Rokka S3 Gateway (:57772)
export AWS_ACCESS_KEY_ID="AKIA_PROD_VAULT_01"
export AWS_SECRET_ACCESS_KEY="SEC_KEY_SOVEREIGN_SECRET_987XYZ"
export AWS_ENDPOINT_URL="https://storage.internal.aarkam:57772"

# Create a sovereign bucket with S3 Object Lock (Compliance WORM enabled)
aws --endpoint-url $AWS_ENDPOINT_URL --no-verify-ssl s3api create-bucket \
    --bucket sovereign-records \
    --object-lock-enabled-for-bucket

# Upload multi-part object
aws --endpoint-url $AWS_ENDPOINT_URL --no-verify-ssl s3 cp dataset.tar.zst s3://sovereign-records/

# Verify bucket inventory
aws --endpoint-url $AWS_ENDPOINT_URL --no-verify-ssl s3 ls s3://sovereign-records/
```

### Python (Boto3)
```python
import boto3
from botocore.client import Config

# Initialize client pointing to local Rokka S3 Gateway (:57772 HTTPS)
s3 = boto3.client(
    's3',
    endpoint_url='https://storage.internal.aarkam:57772',
    aws_access_key_id='AKIA_PROD_VAULT_01',
    aws_secret_access_key='SEC_KEY_SOVEREIGN_SECRET_987XYZ',
    config=Config(signature_version='s3v4', s3={'addressing_style': 'path'}),
    verify=False  # Point to internal enterprise root CA in production
)

# Upload sensitive dataset with server-side encryption metadata
with open("classified_telemetry.parquet", "rb") as data:
    s3.put_object(
        Bucket="sovereign-records",
        Key="telemetry/2026/classified_telemetry.parquet",
        Body=data,
        ServerSideEncryption="AES256"
    )
print("Payload successfully committed to Aarkam Sovereign Fabric.")
```

---

## 10. Comprehensive Ecosystem Test Suite & Quality Assurance (1,300+ Automated Tests)

The Aarkam sovereign platform enforces continuous, multi-layer verification across all decoupled engines. Rather than relying on a single isolated test project, quality assurance is distributed across **14 dedicated test suites comprising 1,323 automated tests** ensuring enterprise-grade stability, zero bitrot, and deterministic behavior:

```
 ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                      AARKAM SOVEREIGN PLATFORM TEST ECOSYSTEM (1,300+ TESTS)                     │
 ├────────────────────────────┬─────────────────────────────┬───────────────────────────────────────┤
 │  CORE STORAGE & DIRECT I/O │ CONSENSUS & S3 INGRESS      │ HARDWARE SENTINEL & ORCHESTRATION     │
 │  • Kdouja Unit (282)       │ • Aarkam.IO Ingress (90)    │ • Abodi Hardware Sentinel (190)       │
 │  • Kdouja Integration (98) │ • S3 SigV4 Compliance (53)  │ • AM Operator CLI (161)               │
 │  • Kdouja E2E (31)         │ • Rokka Raft Mesh (53)      │ • SixFM AI & Chaos Suite (59)         │
 │  • LSM Primitives (138+)   │ • Ahmodi SIMD Math (25)     │                                       │
 ├────────────────────────────┴─────────────────────────────┴───────────────────────────────────────┤
 │ 100% PASS RATE • 11 NINES DURABILITY VERIFIED • ZERO-ALLOCATION WAL & SIMD RECOVERY CERTIFIED   │
 └──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Complete Test Suite Breakdown by Repository

| Subsystem / Repository | Test Projects | Scope & Test Focus | Test Count |
| :--- | :--- | :--- | :---: |
| **`Aarkam.Kdouja`** | `Kdouja.Tests.Unit`<br/>`Kdouja.Tests.Integration`<br/>`Kdouja.Tests.E2E` | Unmanaged arena skip-lists, multi-threaded compactions, crash-recovery WAL replay, 66KB sector alignment, Direct I/O (`O_DIRECT`) zero-copy NVMe persistence | **411 Tests** |
| **`Aarkam.IO.Packages`** | `Aarkam.Kdouja.LSM.Primitives.Tests`<br/>`Kdouja.Tests.Primitives` | Low-level bitwise operations, CRC32C Castagnoli hardware intrinsics, Bloom filter accuracy, binary serialization, cache line alignment | **276 Tests** |
| **`Aarkam.Abodi`** | `Abodi.Tests` | Real-time kernel sysfs/WMI hardware harvesters, NVMe S.M.A.R.T. analytics, predictive Weibull/Holt-Winters failure runway models, autonomous disk drain | **190 Tests** |
| **`Aarkam.AM`** | `AM.CLI.Tests` | Silicon-layer hardware profiler, multi-factor deterministic fingerprinting (`ARK-FP-...`), DPAPI/POSIX secure token caching, disk evacuation workflows | **161 Tests** |
| **`Aarkam` (SCT Platform)** | `Aarkam.IO.IntegrationTests`<br/>`Aarkam.S3.Tests` | Multi-tenant namespace isolation, OpenID Connect & Nafath SSO, Hangfire async scheduling, AWS SigV4 auth, multipart uploads, WORM Object Lock | **143 Tests** |
| **`Aarkam.SixFM`** | `SixFM.UnitTests`<br/>`SixFM.ChaosTests`<br/>`SixFM.Architecture.Tests` | Embedded SLM vector search, Arabic/English NLP semantic embeddings, in-memory cosine similarity, high-concurrency node partition chaos injection | **59 Tests** |
| **`Aarkam.Rokka` (SAT Platform)**| `Rokka.IntegrationTests` | Raft MON quorum leader election, monotonic epoch fencing, Rendezvous consistent hashing, speculative hedged reads, wire-speed S3 chunk routing | **53 Tests** |
| **`Aarkam.Ahmodi`** | `Ahmodi.Tests` | AVX-512 & AVX2 Galois Field $\text{GF}(2^8)$ SIMD vectorization, Cauchy generator matrix inversion, bit-exact (4+2), (8+3), (8+4), (16+4) stripe reconstruction | **25 Tests** |
| **CLI Verification Suite** | `CLI-dummy.Tests` | Bare-metal headless CLI execution, air-gap shell environment probes | **5 Tests** |
| **TOTAL ECOSYSTEM TESTS** | **14 Dedicated Test Suites** | **100% Pass Rate Across Linux x64 & Windows Server x64** | **1,323 Tests** |

---

## 11. Official Documentation Suite

For detailed deployment blueprints, network firewall matrices, and hardware sizing guides, consult the [`docs/`](docs/) directory:

| Document | Title & Focus Area | Target Audience |
| :--- | :--- | :--- |
| [`01_COMPREHENSIVE_REQUIREMENTS_MATRIX.md`](docs/01_COMPREHENSIVE_REQUIREMENTS_MATRIX.md) | Node, Cluster, and AarkamIO Hardware & Kernel Specifications | Infrastructure Architects & SREs |
| [`02_PORTS_AND_NETWORK_FIREWALL_MATRIX.md`](docs/02_PORTS_AND_NETWORK_FIREWALL_MATRIX.md) | Network Zones, MTU 9000 Jumbo Frames, Protocols & Firewall Rules (`ufw`/`firewalld`) | Network & Security Engineers |
| [`03_STORAGE_AND_DRIVE_INFRASTRUCTURE_GUIDE.md`](docs/03_STORAGE_AND_DRIVE_INFRASTRUCTURE_GUIDE.md) | NVMe, Enterprise SSD, SAS HDD, 4Kn Sectors & IT-Mode Controller Runbook | Datacenter Operators & Storage Techs |
| [`04_END_TO_END_INSTALLATION_AND_ACTIVATION_SEQUENCE.md`](docs/04_END_TO_END_INSTALLATION_AND_ACTIVATION_SEQUENCE.md) | Complete Deployment, Hardware Fingerprinting & AarkamCP Genesis Activation | Systems Administrators & DevOps |
| [`05_CTO_SOVEREIGN_ARCHITECTURE_AND_COMPLIANCE_SPEC.md`](docs/05_CTO_SOVEREIGN_ARCHITECTURE_AND_COMPLIANCE_SPEC.md) | Durability Math (11 9s), TCO Analysis vs Cloud, and Regulatory Compliance (NDMO/NCA/SAMA) | CTOs, CISOs, Chief Architects |
| [`06_COO_OPERATIONS_DISASTER_RECOVERY_RUNBOOK.md`](docs/06_COO_OPERATIONS_DISASTER_RECOVERY_RUNBOOK.md) | Business Continuity (RPO=0 / RTO<5s), Fault Domains, and Multi-DC DR | COOs, VP Ops, Incident Commanders |
| [`07_APPLICATION_SUPPORT_AND_S3_SDK_GUIDE.md`](docs/07_APPLICATION_SUPPORT_AND_S3_SDK_GUIDE.md) | S3 API SigV4, Multipart Uploads, and SDK Code Samples (Python, Go, C#, Node.js) | Application Developers & DevOps |

---

## 12. Commercial Licensing & Enterprise Support

Aarkam is commercially distributed under the [Aarkam Commercial Enterprise Sovereign License (ASCEL-v1.0)](LICENSE).

- **Official Operations & Customer Licensing Portal**: [https://aarkam.io/](https://aarkam.io/)
- **Technical Documentation & Knowledge Base**: [https://aarkam.io/Docs](https://aarkam.io/Docs)
- **Enterprise Support Portal**: [https://aarkam.io/Administration/TehcnicalSupport](https://aarkam.io/Administration/TehcnicalSupport)
- **Enterprise Sales & Custom Sovereign Deployment**: [enterprise@aarkam.io](mailto:enterprise@aarkam.io)

---
*© 2026 Aarkam Inc. All Rights Reserved. Sovereign Distributed Storage Infrastructure.*
