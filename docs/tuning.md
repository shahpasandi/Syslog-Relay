# Tuning Guide

## Rsyslog

### High Volume Ingestion
```conf
module(load="imudp" threads="4" batchSize="256")
input(type="imudp" port="514" rcvbufSize="4m")
threads: Increase if CPU has multiple cores.

batchSize: Increase for higher throughput (memory trade-off).

rcvbufSize: Increase UDP buffer to prevent packet drops.

Kernel Tuning
conf
net.core.rmem_max = 8388608
net.core.rmem_default = 8388608
net.core.netdev_max_backlog = 5000
Splunk Universal Forwarder
Remove Throughput Limit
ini
[thruput]
maxKBps = 0
Enable Parallel Pipelines
ini
[general]
parallelIngestionPipelines = 2
Cgroups Limits
ini
[Service]
CPUQuota=20%
MemoryMax=1G
This prevents UF from consuming all server resources during log spikes.

text

---

### 📄 فایل ۱۹: `docs/troubleshooting.md`

```markdown
# Troubleshooting Guide

## Issue: Logs are not appearing in Splunk

### 1. Check Rsyslog
```bash
sudo systemctl status rsyslog
sudo tcpdump -i any -n udp port 514
2. Check Log Files
bash
ls -lh /var/log/remote/<device_type>/<IP>/
3. Check Splunk UF
bash
sudo /opt/splunkforwarder/bin/splunk list monitor
sudo /opt/splunkforwarder/bin/splunk list forward-server
tail -100 /opt/splunkforwarder/var/log/splunk/splunkd.log | grep -i error
4. Check Indexer
Ensure the index exists and is receiving data.

Issue: "seekptr checksum did not match" error in UF
This happens when multiple .gz files have identical headers. Fix:

ini
initCrcLength = 2048
Issue: Disk is full
Check space:

bash
df -h /
du -sh /var/log/remote/*/
Run cleanup script:

bash
sudo /usr/local/bin/cleanup-old-logs.sh
Check Logrotate status:

bash
sudo logrotate -d /etc/logrotate.d/rsyslog-remote
