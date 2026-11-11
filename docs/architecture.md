# Architecture Details

This document explains the data flow, design decisions, and key architectural choices behind Syslog Relay for Splunk.

## Data Flow

1. **Network Devices** send Syslog messages (UDP 514).
2. **Rsyslog** receives messages and uses a `ruleset` to route them to device-specific directories based on `$fromhost-ip`.
3. **Rsyslog** writes raw logs to `/var/log/remote/<device_type>/<IP>/<YYYY-MM-DD-HH>.log`.
4. **Logrotate** rotates logs based on size (`maxsize 50M`) and time (`hourly`), keeping 4 versions (`rotate 4`).
5. **Splunk UF** monitors `/var/log/remote/` recursively, reading `.log` and `.log.1` files (thanks to `whitelist`).
6. **Splunk UF** forwards logs to the **Splunk Indexer** (TCP 9997).

## Directory Structure on Disk

```
/var/log/remote/
├── fortigate/
│   └── 192.0.2.1/
│       ├── 2026-10-25-13.log        # Active log file
│       ├── 2026-10-25-13.log.1      # Most recent rotated file (uncompressed)
│       └── 2026-10-25-13.log.2.gz   # Older rotated file (compressed)
├── sophos/
│   ├── 192.0.2.10/
│   ├── 192.0.2.11/
│   └── 192.0.2.12/
├── cisco/
│   └── 10.10.150.1/
└── others/
    └── <unknown_device_ip>/
```

## Key Design Decisions

### Why Rulesets?

Using `ruleset` in Rsyslog prevents remote logs from being written to `/var/log/syslog` (the local system log). This is critical for two reasons:

1. **Security**: Local system logs should only contain events from the server itself. Mixing network device logs with local logs makes auditing difficult.
2. **Performance**: Writing high-volume firewall logs to `/var/log/syslog` can cause disk I/O bottlenecks and fill the root partition.

### Why `initCrcLength = 2048`?

Network devices often have identical headers in their logs (e.g., `device_name="..."` for Sophos, `devname="..."` for FortiGate). Splunk UF uses the first 256 bytes (by default) to calculate a CRC for file identification.

If multiple `.gz` files have identical headers, UF will think they are the same file and skip them. This leads to **missing logs** in Splunk.

Setting `initCrcLength = 2048` forces UF to read more data, ensuring unique CRCs for each file.

### Why `whitelist` instead of `blacklist`?

- **`whitelist = \.log$|\.log\.1$`** explicitly tells UF to only read `.log` and `.log.1` files.
- This prevents UF from reading `.gz` files (which would cause duplicate ingestion).
- It also ensures UF reads the latest rotated file (`.log.1`), which may still contain unread data.

Using `blacklist` is less safe because it allows any file that doesn't match the pattern to be read, which could lead to unexpected behavior.

### Why `delaycompress`?

`delaycompress` tells Logrotate to keep the most recent rotated file uncompressed (`.log.1`). This gives UF time to read it before it's compressed to `.gz`.

Without `delaycompress`, the file would be immediately compressed to `.gz`, and UF would never read it (since `.gz` files are excluded by `whitelist`).

### Why `maxsize 50M`?

Firewall logs can grow very quickly (e.g., 200+ MB per hour). Relying only on `hourly` rotation would create huge files that are slow for UF to read and may cause disk space issues.

Setting `maxsize 50M` ensures files are rotated as soon as they reach 50 MB, even before the hour is up. This keeps file sizes manageable and prevents disk exhaustion.

### Why `rotate 4`?

`rotate 4` keeps the last 4 rotated files. Since Logrotate runs every 5 minutes and files are rotated at 50 MB, 4 versions provide enough history for UF to catch up if it falls behind temporarily.

For high-volume environments, this can be reduced to `rotate 2` to save disk space.

### Why Cgroups Limits?

Universal Forwarder does not natively limit CPU or RAM usage. During log spikes or misconfigurations (e.g., debug mode), UF can consume all server resources and cause the entire system to become unresponsive.

Cgroups limits prevent this:

```ini
[Service]
CPUQuota=20%
MemoryMax=1G
```

This ensures UF never uses more than 20% of one CPU core and 1 GB of RAM, leaving resources for Rsyslog, Logrotate, and the OS itself.
