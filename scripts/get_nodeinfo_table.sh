#!/bin/bash
# This script is used to get the nodeinfo table from the database

# Iterate through the all the directories in the current directory starting wiht yb*
function get_node_info() {
    tempfile=$(mktemp)
    echo "Nodename|Type|Hostname|RPC IP|Webserver IP|UUID" > $tempfile
    for d in $(ls -d yb*); do
        for type in master tserver; do
            log_file="$d/$type/logs/*INFO*"
            echo "Checking $log_file"
            if grep -q 'Node information.*' $log_file 2>/dev/null; then
                node_info=$(grep -Eoh 'Node information.*' $log_file | head -n 1)
                hostname=$(echo $node_info | sed "s/.*hostname: '//g" | sed "s/', rpc_ip:.*//g")
                rpc_ip=$(echo $node_info | sed "s/.*rpc_ip: '//g" | sed "s/', webserver_ip:.*//g")
                webserver_ip=$(echo $node_info | sed "s/.*webserver_ip: '//g" | sed "s/', uuid:.*//g")
                uuid=$(echo $node_info | sed "s/.*uuid: '//g" | sed "s/' }.*//g")
                echo "$d | $type | $hostname | $rpc_ip | $webserver_ip | $uuid" >> $tempfile
            fi
        done
    done
    column -t -s '|' $tempfile | tee node_info.txt
    rm $tempfile
}

# grep -E 'Node information.*' yb-prod-kfin-onprem-app-read-n1/master/logs/*INFO* | head -n 1 | awk '{print $6}' | sed "s/\\'//g"