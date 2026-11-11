#!/bin/bash
# cleanup-old-logs.sh
# Removes .gz and .log.1 files older than 24 hours from /var/log/remote

find /var/log/remote/ -type f \( -name "*.gz" -o -name "*.log.1" \) -mmin +1440 -delete
