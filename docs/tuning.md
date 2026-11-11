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
