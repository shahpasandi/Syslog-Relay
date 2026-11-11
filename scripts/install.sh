#!/bin/bash
# install.sh
# Installs and configures Syslog Relay on Ubuntu 24.04

set -e

echo "🚀 Starting Syslog Relay installation..."

# 1. Update and install packages
echo "📦 Installing required packages..."
apt-get update
apt-get install -y rsyslog logrotate tcpdump ufw

# 2. Copy rsyslog configs
echo "📝 Configuring Rsyslog..."
cp configs/rsyslog/rsyslog.conf /etc/rsyslog.conf
cp configs/rsyslog/remote.conf /etc/rsyslog.d/remote.conf

# 3. Copy logrotate configs
echo "🔄 Configuring Logrotate..."
cp configs/logrotate/rsyslog-remote /etc/logrotate.d/rsyslog-remote
cp configs/logrotate/rsyslog-local /etc/logrotate.d/rsyslog

# 4. Copy sysctl config
echo "⚙️ Tuning Kernel parameters..."
cp configs/sysctl/99-rsyslog.conf /etc/sysctl.d/99-rsyslog.conf
sysctl -p /etc/sysctl.d/99-rsyslog.conf

# 5. Create log directories
echo "📁 Creating log directories..."
mkdir -p /var/log/remote/{fortigate,sophos,cisco,others}
chown -R syslog:adm /var/log/remote
chmod 755 /var/log/remote

# 6. Copy cleanup script
echo "🧹 Installing cleanup script..."
cp scripts/cleanup-old-logs.sh /usr/local/bin/cleanup-old-logs.sh
chmod +x /usr/local/bin/cleanup-old-logs.sh

# 7. Setup Cron jobs
echo "⏰ Setting up Cron jobs..."
crontab configs/cron/syslog-relay-cron

# 8. Configure Firewall
echo "🔥 Configuring Firewall..."
ufw allow 514/udp
ufw reload

# 9. Restart Rsyslog
echo "🔄 Restarting Rsyslog..."
systemctl restart rsyslog
systemctl enable rsyslog

echo "✅ Installation complete!"
echo ""
echo "⚠️  IMPORTANT: Please configure your network devices to send Syslog to this server on UDP 514."
echo "⚠️  IMPORTANT: Install Splunk UF manually and copy configs from configs/splunk-uf/."
