# Troubleshooting Guide

This guide covers common issues you may encounter while using this project and how to resolve them.

## Issue: Logs are not appearing in Splunk

### 1. Check Rsyslog Status

```bash
sudo systemctl status rsyslog
```

Ensure Rsyslog is running without errors.

### 2. Verify Incoming Traffic

```bash
sudo tcpdump -i any -n udp port 514
```

If you don't see packets, your devices are not sending logs to this server. Check the Syslog configuration on your network devices.

### 3. Check Log Files on Disk

```bash
ls -lh /var/log/remote/<device_type>/<IP>/
```

If the directory is empty, Rsyslog is not writing logs. Check the `remote.conf` ruleset and ensure the device IP is defined there.

### 4. Check Splunk UF Status

```bash
sudo /opt/splunkforwarder/bin/splunk list monitor
sudo /opt/splunkforwarder/bin/splunk list forward-server
```

- `list monitor` should show `/var/log/remote/fortigate`, `/var/log/remote/sophos`, and `/var/log/remote/cisco`.
- `list forward-server` should show your Splunk Indexer IP and port.

### 5. Check UF Logs for Errors

```bash
tail -100 /opt/splunkforwarder/var/log/splunk/splunkd.log | grep -i error
```

Look for errors like `index not found`, `connection refused`, or `No route to host`.

### 6. Check Splunk Indexer

Ensure the index (`fw` or `cisco`) exists and is receiving data. Use the following search in Splunk:

```
| eventcount summarize=false index=fw
| eventcount summarize=false index=cisco
```

If the index does not exist, create it in Splunk:

```bash
sudo -u splunk /opt/splunk/bin/splunk add index fw -auth admin:password
sudo -u splunk /opt/splunk/bin/splunk add index cisco -auth admin:password
```

## Issue: "seekptr checksum did not match" error in UF

This error occurs when multiple `.gz` files have identical headers (e.g., all Sophos logs start with `device_name="..."`). Universal Forwarder uses the first 256 bytes to calculate a CRC, and if two files have the same header, UF skips one of them.

**Fix**: Increase `initCrcLength` in `inputs.conf`:

```ini
[monitor:///var/log/remote/sophos]
initCrcLength = 2048
```

## Issue: Disk is full

### 1. Check Disk Space

```bash
df -h /
du -sh /var/log/remote/*/
```

### 2. Run Cleanup Script

```bash
sudo /usr/local/bin/cleanup-old-logs.sh
```

This script removes `.gz` and `.log.1` files older than 24 hours.

### 3. Verify Logrotate Configuration

```bash
sudo logrotate -d /etc/logrotate.d/rsyslog-remote
```

The `-d` flag runs Logrotate in dry-run mode and shows what it would do without actually rotating files. Look for errors like `insecure permissions` or `unknown option`.

### 4. Check Logrotate Status

```bash
sudo cat /var/lib/logrotate/status | grep remote
```

This shows the last rotation time for each file.

## Issue: Logrotate is not rotating files

### 1. Check the Logrotate Configuration

```bash
sudo logrotate -d /etc/logrotate.d/rsyslog-remote
```

### 2. Check for "insecure permissions" error

If you see:

```
error: skipping "/var/log/remote/..." because parent directory has insecure permissions
```

Add `su root adm` to the Logrotate configuration:

```conf
/var/log/remote/*/*/*.log {
    su root adm
    ...
}
```

### 3. Check Cron

```bash
sudo crontab -l | grep logrotate
```

Ensure the cron job is present:

```cron
*/5 * * * * /usr/sbin/logrotate /etc/logrotate.d/rsyslog-remote
```

## Issue: UF is not sending logs despite being "running"

This is a known issue caused by throughput limits or blocked queues.

### 1. Remove Throughput Limit

```ini
[thruput]
maxKBps = 0
```

### 2. Enable Parallel Pipelines

```ini
[general]
parallelIngestionPipelines = 2
```

### 3. Check UF Metrics

```bash
grep "tcpout" /opt/splunkforwarder/var/log/splunk/metrics.log | tail -20
```

Look for `queued` values. If they are high, UF is backlogged.

### 4. Restart UF

```bash
sudo /opt/splunkforwarder/bin/splunk restart
