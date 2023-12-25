#!/bin/bash

# The output file will contain the following columns:
# 1. Date and time
# 2. CPU usage (%)
# 3. Network usage (bytes/sec)
# 4. Memory usage (%)
# 5. Disk IO (bytes/sec)

# The script will run every 15 minutes and append the output to the file.
# Network column will contain the sum of bytes sent and received.
# Disk IO column will contain the sum of bytes read and written.
# Free memory column will contain the sum of free memory and available memory.

network_device_name="ens160"
disk_device_name="sda"

get_cpu_usage() {
    uptime | awk '{print $10}' | sed 's/,//'
}
get_network_usage() {
    sar -n DEV 1 1 | grep Average | grep $network_device_name | awk '{print $5,$6}'
}
get_memory_usage() {
    free | grep Mem | awk '{print $4,$7'}
}
get_disk_io() {
    sar -d 1 1 | grep Average | grep $disk_device_name | awk '{print $4,$5}'
}

echo "Date and time | CPU usage (%) | Network usage Rx/Tx | Memory usage (Free/Available) | Disk IO (Read/Write)" > system_monitoring.txt

while true; do
    cpu_usage=$(get_cpu_usage)
    network_usage=$(get_network_usage)
    memory_usage=$(get_memory_usage)
    disk_io=$(get_disk_io)
    date_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$date_time | $cpu_usage | $network_usage | $memory_usage | $disk_io" >> system_monitoring.txt
    sleep 900
done