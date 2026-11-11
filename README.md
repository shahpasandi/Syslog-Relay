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
