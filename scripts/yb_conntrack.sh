# Script to get store netstat -anp results in a file and connections count in a another file
# Usage: ./conntrack.sh
mkdir /tmp/conntrack

# Function to get disk utilization of /tmp
get_disk_utilization() {
    df -h /tmp | tail -n +2 |awk '{print $5}' |sed s/%//g
}


while true; do
    # date in YYYY-MM-DD format
    date=$(date +%Y-%m-%d)
    # Break if disk utilization is more than 80%
    if [ $(get_disk_utilization) -gt 80 ]; then
        break
    fi
    # get connection tracking information
    cat /proc/1/net/nf_conntrack > /tmp/conntrack/$date.txt
    # get connections count
    connections=$(wc -l /proc/1/net/nf_conntrack | awk '{print $1}')
    # get inbound connections count
    inbound=$(curl http://127.0.0.1:12000/rpcz |grep remote_ip | wc -l)
    # write results to file
    echo "$date : $connections : $inbound" >> /tmp/conntrack/connections.txt
    # sleep for 5 minutes
    sleep 300
done


