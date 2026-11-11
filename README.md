# Syslog Relay for Splunk

A production-grade, disk-backed Syslog relay server that receives logs from network devices (Firewalls, Switches, Routers), stores them reliably on disk, and forwards them to Splunk via Universal Forwarder (UF).

![Architecture](docs/architecture.png)

## 🎯 Features

- **Multi-Device Support**: FortiGate, Sophos, Cisco IOS, and any standard Syslog sender.
- **Disk-Backed Persistence**: Logs are written to disk *before* being forwarded. If Splunk goes down, no data is lost.
- **High Performance**: Tuned Rsyslog for high-volume ingestion (UDP 514).
- **Automatic Log Rotation**: Managed by `logrotate` with size and time-based rotation.
- **Resource Control**: UF is constrained using Systemd Cgroups to prevent resource exhaustion.
- **No Duplicate Ingestion**: Tuned `initCrcLength` and `whitelist` to prevent UF from re-reading rotated files.
- **Automated Cleanup**: A cleanup script removes old `.gz` and `.log.1` files to keep disk usage stable.

## 🏗️ Architecture

```
Network Devices ──(UDP 514)──> Rsyslog Relay ──> /var/log/remote/ ──> Splunk UF ──(TCP 9997)──> Splunk Indexer
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

## 🚀 Installation

### 1. Clone the repository
```bash
git clone https://github.com/your-username/syslog-relay.git
cd syslog-relay
```

### 2. Run the installation script
```bash
sudo chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

### 3. Configure your devices
Point your network devices to send Syslog to the relay server's IP on **UDP 514**.

### 4. Configure Splunk UF
Edit `configs/splunk-uf/inputs.conf` and `outputs.conf` with your Splunk Indexer IP and credentials.

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

## 📚 Documentation

- [Architecture Details](docs/architecture.md)
- [Tuning Guide](docs/tuning.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
```
