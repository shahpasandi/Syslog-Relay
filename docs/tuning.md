# Tuning Guide

## Rsyslog

### High Volume Ingestion
```conf
module(load="imudp" threads="4" batchSize="256")
input(type="imudp" port="514" rcvbufSize="4m")
