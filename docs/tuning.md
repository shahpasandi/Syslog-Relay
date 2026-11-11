# Tuning Guide

This guide explains the key tuning parameters used in this project to handle high-volume log ingestion and ensure stable operation.

## Rsyslog

### High Volume Ingestion

```conf
module(load="imudp" threads="4" batchSize="256")
input(type="imudp" port="514" rcvbufSize="4m")
```

- **`threads`**: Increase if the CPU has multiple cores. More threads allow Rsyslog to process incoming UDP packets in parallel.
- **`batchSize`**: Increase for higher throughput. This is a memory trade-off: larger batches use more RAM but reduce processing overhead.
- **`rcvbufSize`**: Increase the UDP receive buffer to prevent packet drops during traffic spikes.

### Kernel Tuning

```conf
net.core.rmem_max = 8388608
net.core.rmem_default = 8388608
net.core.netdev_max_backlog = 5000
```

- **`rmem_max` / `rmem_default`**: Set the maximum and default UDP receive buffer size to 8 MB. This is critical for high-volume Syslog.
- **`netdev_max_backlog`**: Increase the number of packets queued at the network device layer to handle bursts.

## Splunk Universal Forwarder

### Remove Throughput Limit

```ini
[thruput]
maxKBps = 0
```

By default, UF limits its throughput to **256 Kbps**. Setting `maxKBps = 0` removes this limit, allowing UF to use the full available bandwidth.

> ⚠️ **Warning**: Removing this limit can cause UF to consume significant CPU and network resources. Always pair this with Cgroups limits (see below).

### Enable Parallel Pipelines

```ini
[general]
parallelIngestionPipelines = 2
```

This allows UF to process multiple files in parallel. It is especially useful when you have a mix of large files (e.g., Firewall logs) and small files (e.g., Switch logs).

### Cgroups Limits

```ini
[Service]
CPUQuota=20%
MemoryMax=1G
```

This prevents UF from consuming all server resources during log spikes or misconfigurations (e.g., debug mode).

- **`CPUQuota=20%`**: UF can use at most 20% of one CPU core.
- **`MemoryMax=1G`**: UF can use at most 1 GB of RAM.

## Logrotate

### Remote Logs

```conf
/var/log/remote/*/*/*.log {
    hourly
    maxsize 50M
    rotate 4
    maxage 1
    compress
    delaycompress
    missingok
    notifempty
    create 0640 syslog adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

- **`hourly`**: Rotate logs every hour.
- **`maxsize 50M`**: Rotate immediately if a file reaches 50 MB, even before the hour is up.
- **`rotate 4`**: Keep the last 4 rotated files.
- **`maxage 1`**: Delete rotated files older than 1 day.
- **`delaycompress`**: Keep the most recent rotated file uncompressed (`.log.1`) so UF can read it before it's compressed.
- **`sharedscripts`**: Run the `postrotate` script only once for all files.

### Local System Logs

```conf
/var/log/syslog
/var/log/mail.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/cron.log
{
    su root adm
    daily
    maxsize 100M
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

- **`su root adm`**: Required on Ubuntu 24.04 to avoid `insecure permissions` errors.
- **`daily` + `maxsize 100M`**: Rotate daily, or immediately if the file exceeds 100 MB.
- **`rotate 7`**: Keep the last 7 rotated files (one week of history).

## Cron Jobs

```cron
# Rotate remote logs every 5 minutes
*/5 * * * * /usr/sbin/logrotate /etc/logrotate.d/rsyslog-remote

# Cleanup old .gz and .log.1 files daily at 3 AM
0 3 * * * /usr/local/bin/cleanup-old-logs.sh
```

- **`*/5 * * * *`**: Run Logrotate every 5 minutes. This ensures files are rotated as soon as they reach `maxsize`.
- **`0 3 * * *`**: Run the cleanup script every day at 3 AM to remove old compressed files and keep disk usage stable.
