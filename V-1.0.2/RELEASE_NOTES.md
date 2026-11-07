# Abodi Sovereign Hardware Diagnostics & Storage Node Agent
# Official Production Release Notes (Version 1.0.2-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | Abodi Sovereign Storage & Diagnostics Node Daemon |
| **Release Version** | `v1.0.2-GA (General Availability)` |
| **Release Date** | November 2026 |
| **Architectural Role** | Unified Physical Storage Node Agent & Hardware Telemetry Engine |
| **Dependency Scope** | Core Foundation for **Aarkam - SAT (Standalone Tier: Rokka Substrate)** & **Aarkam - SCT (Storage Centers Tier: Aarkam.IO Cloud)** |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64, OCI Container) |

---

## 1. Executive Summary

**Abodi v1.0.2-GA** establishes complete sovereign networking parity with **Rokka v1.0.2** and **AM CLI v1.0.2**. This release brings automatic sovereign URL normalization, expanded sovereign audience and issuer validation, flexible port 443 support, package synchronization to modern **.NET 10** dependencies, and refined multi-platform installer scripts.

---

## 2. What's New in Version 1.0.2-GA

### 2.1 Sovereign URL Normalization & Connection Resilience
- **Sovereign Domain Default**: Default Coordinator connection URL updated to `https://rokka-coordinator.aarkam:57774`.
- **Automatic Scheme & Port 443 Handling**: The installer and reachability probes accept bare domain names (`rokka-coordinator.aarkam`), custom on-premises IP addresses (`10.20.0.10:57774`), and reverse proxy configurations on port 443 without requiring redundant `:443` port suffixes.
- **Scheme Auto-Injection**: Automatically prepends `https://` if omitted by operators during registration.

### 2.2 Sovereign Security Token Alignment
- **Expanded Token Validation**: Updated `ClusterSecurityTokenValidator` to recognize sovereign cluster token issuers and audiences:
  - `https://rokka-coordinator.aarkam`
  - `https://rokka-gateway.aarkam`
  - `https://abodi.aarkam`
  - `urn:rokka:gateway`
  - `urn:rokka:abodi`
- **Dynamic `.aarkam` Domain Trust**: Any host belonging to the sovereign `.aarkam` domain hierarchy is automatically admitted for internal cluster verification.

### 2.3 Package & Dependency Modernization (.NET 10)
- **Windows Services**: Upgraded `Microsoft.Extensions.Hosting.WindowsServices` from `9.0.0` to `10.0.11` to match the rest of the .NET 10 hosting stack.
- **Logging & Diagnostics**: Synchronized Serilog footprint properties (`AgentVersion` set to `v1.0.2`).
- **Global Versioning**: Added `Directory.Build.props` establishing deterministic assembly versioning across all solution projects.

### 2.4 Complemented Ecosystem Trilogy
- Seamlessly paired with **Rokka v1.0.2** and **AM CLI v1.0.2**.
- Unified workflow: token generation via `am node token create`, automated installation via `install-abodi.sh` / `install-abodi.ps1`, and immediate fleet registration in `am node list`.

---

## 3. Package & Distribution Matrix

| Artifact Name | Target Architecture | Contents | Distribution Channel |
| :--- | :--- | :--- | :--- |
| **`abodi-v1.0.2-linux-x64.zip`** | Linux x64 (glibc 2.31+) | Standalone `Abodi`, `install-abodi.sh`, configurations | [GitHub Releases](https://github.com/aarkamio/Aarkam/releases) |
| **`abodi-v1.0.2-win-x64.zip`** | Windows Server x64 (2022/2025) | Standalone `Abodi.exe`, `install-abodi.ps1`, configurations | [GitHub Releases](https://github.com/aarkamio/Aarkam/releases) |
| **`aarkam/aarkam.abodi:v1.0.2`** | OCI Container (Linux x64) | Enterprise container with embedded `smartmontools`, `nvme-cli` | [Docker Hub](https://hub.docker.com/r/aarkam/aarkam.abodi) |
