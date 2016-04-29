#!/bin/bash

usage() {
    echo "usage: set-allocation.sh <on|off> <target-node-and-port>"
}

if [ "x$1" != "x" ]; then
    action=$1
else
    echo "Arguments not given" >&2
    usage
    exit 1
fi

if [ "x$2" != "x" ]; then
    node=$2
else
    echo "Wrong number of arguments" >&2
    usage
    exit 1
fi

json='{
    "transient" : {
        "cluster.routing.allocation.disable_allocation": SETTING,
        "cluster.routing.allocation.disable_replica_allocation": SETTING 
    }
}'

if [ "$action" == "off" ]; then
    setting="true"
elif [ "$action" == "on" ]; then
    setting="false"
else
    echo "Invalid action '$action'" >&2
    usage
    exit 1
fi

curl_result=`echo $json | sed -e "s/SETTING/$setting/g" \
                 | curl -s -XPUT "$node/_cluster/settings" -d @-`
status_check=`echo $curl_result | awk '/"ok":true/'`

if [ "$status_check" != "" ]; then
    echo "OK"
    exit 0
else
    echo "Elasticsearch request failed:" >&2
    echo $curl_result >&2
    exit 1
fi
