#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$()
service=$(sudo systemctl status $folder --no-pager | grep "active (running)" | wc -l)
errors=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")
rate_hour=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {printf "%0.2f",sum}')
rate_day=$(journalctl -u $folder.service --since "1 day ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {printf "%0.2f",sum}')

status="ok" && message="rate $rate_hour/$rate_day"
[ $errors -gt 500 ] && status="warning" && message="errors=$errors";
[ $service -ne 1 ] && status="error" && message="service not running";

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "project":"$folder",
       "id":"$ID",
       "grp":"node2"
  },
  "fields": {
        "machine":"$MACHINE",
        "owner":"$OWNER",
        "chain":"eclipse",
        "network":"mainnet",
        "version":"$version",
        "status":"$status",
        "message":"$message",
        "service":$service,
        "errors":$errors,
        "url":"",
        "rate_hour":"$rate_hour",
        "rate_day":"$rate_day"
  }
}
EOF

cat $json | jq
