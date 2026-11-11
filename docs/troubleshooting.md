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
