# Syslog Relay for Splunk

A production-grade, disk-backed Syslog relay server that receives logs from network devices (Firewalls, Switches, Routers), stores them reliably on disk, and forwards them to Splunk via Universal Forwarder (UF).

## 🎯 Features

- **Multi-Device Support**: FortiGate, Sophos, Cisco IOS, and any standard Syslog sender.
- **Disk-Backed Persistence**: Logs are written to disk *before* being forwarded. If Splunk goes down, no data is lost.
- **High Performance**: Tuned Rsyslog for high-volume ingestion (UDP 514).
- **Automatic Log Rotation**: Managed by `logrotate` with size and time-based rotation.
- **Resource Control**: UF is constrained using Systemd Cgroups to prevent resource exhaustion.
- **No Duplicate Ingestion**: Tuned `initCrcLength` and `whitelist` to prevent UF from re-reading rotated files.
- **Automated Cleanup**: A cleanup script removes old `.gz` and `.log.1` files to keep disk usage stable.

## 🏗️ Architecture

```text
┌─────────────────┐     UDP 514      ┌──────────────────┐    TCP 9997    ┌─────────────────┐
│ Network Devices ├─────────────────►│  Rsyslog Relay   ├───────────────►│ Splunk Indexer  │
│ (FortiGate,     │                  │                  │                │                 │
│  Sophos, Cisco) │                  │ /var/log/remote/ │                │                 │
└─────────────────┘                  └──────────────────┘                └─────────────────┘
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │  Splunk UF       │
                                     │  (Monitors Disk) │
                                     └──────────────────┘
```

## 🆚 Why Not Splunk Connect for Syslog (SC4S)?

Splunk provides an official, open-source solution called [Splunk Connect for Syslog (SC4S)](https://github.com/splunk/splunk-connect-for-syslog). While SC4S is an excellent tool, it is fundamentally different from this project:

| Feature | Syslog Relay (This Project) | Splunk Connect for Syslog (SC4S) |
| :--- | :--- | :--- |
| **Transport** | Universal Forwarder (UF) | HTTP Event Collector (HEC) |
| **Disk Storage** | **✅ Logs are written to disk first.** | **❌ Logs are sent directly via HEC.** |
| **Data Persistence** | **✅ Survives Splunk outages.** Logs remain on disk and are forwarded when Splunk recovers. | **❌ Risk of data loss.** If HEC or the network is down, in-memory logs can be lost. |
| **Parsing** | Done at Search Time (Splunk `props.conf`). | Done at Ingest Time (SC4S transforms logs to JSON). |
| **Complexity** | Manual configuration of Rsyslog, Logrotate, and UF. | Packaged as a container (Docker/Kubernetes) with built-in log sources. |

**Key Advantage of This Project:**
If your Splunk Indexer is down for maintenance, or if there's a network outage, **this project will not lose any logs**. Rsyslog writes everything to disk, and the Universal Forwarder will send the backlog once connectivity is restored. SC4S, by design, does not use disk persistence and relies entirely on HEC.

**When to choose SC4S:**
- You want a "plug-and-play" container with built-in parsers for hundreds of device types.
- You don't need disk-level persistence (e.g., your network is highly reliable).

**When to choose this project:**
- You need **guaranteed data durability** on disk.
- You want full control over the OS, log rotation, and UF tuning.
- You are comfortable managing a Linux server.

## 📋 Requirements

- **OS**: Ubuntu 24.04 LTS (or any modern Linux distro with systemd).
- **CPU**: 4 vCPU (Recommended).
- **RAM**: 8 GB (Recommended).
- **Disk**: 100+ GB (Depends on log volume and retention).
- **Splunk**: Indexer with UF receiving port enabled.

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/syslog-relay.git
cd syslog-relay

# 2. Run the installation script
sudo chmod +x scripts/install.sh
sudo ./scripts/install.sh

# 3. Configure Splunk Indexer IP
sudo nano configs/splunk-uf/outputs.conf

# 4. Install Splunk UF (manual step)
# Follow: https://docs.splunk.com/Documentation/Forwarder

# 5. Send a test log
logger -n 127.0.0.1 -P 514 "Test log from syslog-relay"
```

## 📁 Directory Structure

```text
syslog-relay/
├── configs/                    # Configuration files
│   ├── rsyslog/
│   │   ├── rsyslog.conf        # Main Rsyslog config
│   │   └── remote.conf         # Ruleset for remote logs
│   ├── logrotate/
│   │   ├── rsyslog-local       # Local system logs rotation
│   │   └── rsyslog-remote      # Remote logs rotation
│   ├── sysctl/
│   │   └── 99-rsyslog.conf     # Kernel tuning
│   ├── splunk-uf/
│   │   ├── inputs.conf         # UF inputs
│   │   ├── outputs.conf        # UF outputs (Splunk Indexer)
│   │   ├── limits.conf         # UF throughput
│   │   ├── server.conf         # UF parallel pipelines
│   │   └── SplunkForwarder.service.d_override.conf  # Cgroups limits
│   └── cron/
│       └── syslog-relay-cron   # Cron jobs
├── scripts/
│   ├── install.sh              # Automated installer
│   └── cleanup-old-logs.sh     # Old log cleanup script
├── docs/
│   ├── architecture.md         # Detailed architecture
│   ├── tuning.md               # Tuning guide
│   └── troubleshooting.md      # Troubleshooting guide
├── LICENSE                     # Apache 2.0
└── README.md                   # This file
```

## ⚙️ Configuration Files

All configuration files are located in the `configs/` directory:

- **Rsyslog**: `configs/rsyslog/`
- **Logrotate**: `configs/logrotate/`
- **Sysctl**: `configs/sysctl/`
- **Splunk UF**: `configs/splunk-uf/`

## 🧹 Log Cleanup

A cleanup script is provided to remove old `.gz` and `.log.1` files after 24 hours:

```bash
/usr/local/bin/cleanup-old-logs.sh
```

This script is automatically run daily at 3 AM via Cron.

## 🧪 Tested On

- **OS**: Ubuntu 24.04 LTS (Server)
- **Rsyslog**: v8.2312.0
- **Splunk Universal Forwarder**: v10.x
- **Devices**: FortiGate 200F, Sophos XGS 2300, Cisco IOS (Catalyst)

## 🔒 Security Considerations

- **No TLS**: This project uses UDP 514 (plaintext). For encrypted transport, consider using TCP with TLS (`imtcp` + `gtls`).
- **Firewall**: Ensure UDP 514 is only accessible from trusted network segments.
- **UF Credentials**: Never commit `outputs.conf` with real credentials. Use environment variables or a secrets manager.
- **Indexer IP**: Replace `<SPLUNK_INDEXER_IP>` in `outputs.conf` with your actual Splunk Indexer IP address.

## 📚 Documentation

- [Architecture Details](docs/architecture.md)
- [Tuning Guide](docs/tuning.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
