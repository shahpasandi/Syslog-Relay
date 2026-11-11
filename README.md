# Syslog Relay for Splunk

A production-grade, centralized Syslog relay server that receives logs from network devices (Firewalls, Switches, Routers), stores them on disk, and forwards them to Splunk via Universal Forwarder (UF).

![Architecture](docs/architecture.png)

## 🎯 Features

- **Multi-Device Support**: FortiGate, Sophos, Cisco IOS, and any standard Syslog sender.
- **High Performance**: Tuned Rsyslog for high-volume ingestion (UDP 514).
- **Data Persistence**: Logs are written to disk before being forwarded to Splunk, preventing data loss during outages.
- **Automatic Log Rotation**: Managed by `logrotate` with size and time-based rotation.
- **Resource Control**: UF is constrained using Systemd Cgroups to prevent resource exhaustion.
- **No Duplicate Ingestion**: Tuned `initCrcLength` and `whitelist` to prevent UF from re-reading rotated files.

## 🏗️ Architecture
Network Devices ──(UDP 514)──> Rsyslog Relay ──> /var/log/remote/ ──> Splunk UF ──(TCP 9997)──> Splunk Indexer

text

## 📋 Requirements

- **OS**: Ubuntu 24.04 LTS (or any modern Linux distro with systemd).
- **CPU**: 4 vCPU (Recommended).
- **RAM**: 8 GB (Recommended).
- **Disk**: 100+ GB (Depends on log volume and retention).
- **Splunk**: Indexer with HEC or UF receiving port enabled.

## 🚀 Installation

### 1. Clone the repository
```bash
git clone https://github.com/your-username/syslog-relay.git
cd syslog-relay
2. Run the installation script
bash
sudo chmod +x scripts/install.sh
sudo ./scripts/install.sh
3. Configure your devices
Point your network devices to send Syslog to the relay server's IP on UDP 514.

4. Configure Splunk UF
Edit configs/splunk-uf/inputs.conf and outputs.conf with your Splunk Indexer IP and credentials.

⚙️ Configuration Files
All configuration files are located in the configs/ directory:

Rsyslog: configs/rsyslog/

Logrotate: configs/logrotate/

Sysctl: configs/sysctl/

Splunk UF: configs/splunk-uf/

🧹 Log Cleanup
A cleanup script is provided to remove old .gz and .log.1 files after 24 hours:

bash
/usr/local/bin/cleanup-old-logs.sh
📚 Documentation
Architecture Details

Tuning Guide

Troubleshooting

🤝 Contributing
Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
