# Architecture Details

## Data Flow

1. **Network Devices** send Syslog messages (UDP 514).
2. **Rsyslog** receives messages and uses a `ruleset` to route them to device-specific directories based on `$fromhost-ip`.
3. **Rsyslog** writes raw logs to `/var/log/remote/<device_type>/<IP>/<YYYY-MM-DD-HH>.log`.
4. **Logrotate** rotates logs based on size (`maxsize 50M`) and time (`hourly`), keeping 4 versions (`rotate 4`).
5. **Splunk UF** monitors `/var/log/remote/` recursively, reading `.log` and `.log.1` files (thanks to `whitelist`).
6. **Splunk UF** forwards logs to the **Splunk Indexer** (TCP 9997).

## Key Design Decisions

### Why Rulesets?

Using `ruleset` in Rsyslog prevents remote logs from being written to `/var/log/syslog` (local system log). This is critical for security and performance.

### Why `initCrcLength = 2048`?

Network devices often have identical headers in their logs (e.g., `device_name="..."`). Splunk UF uses the first 256 bytes (by default) to calculate a CRC for file identification. If multiple `.gz` files have identical headers, UF will think they are the same file and skip them. `initCrcLength = 2048` forces UF to read more data, ensuring unique CRCs.

### Why `whitelist` instead of `blacklist`?

- `whitelist = \.log$|\.log\.1$` explicitly tells UF to only read `.log` and `.log.1` files.
- This prevents UF from reading `.gz` files (which would cause duplicate ingestion) and ensures it reads the latest rotated file.

### Why `delaycompress`?

`delaycompress` tells Logrotate to keep the most recent rotated file uncompressed (`.log.1`). This gives UF time to read it before it's compressed to `.gz`.
