#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$()
service=$(sudo systemctl status $folder --no-pager | grep "active (running)" | wc -l)
errors=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")
rate-hour=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {print sum}')
rate-day=$(journalctl -u $folder.service --since "1 day ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {print sum}')

status="ok" && message=""
[ $errors -gt 500 ] && status="warning" && message="errors=$errors";
[ $service -ne 1 ] && status="error" && message="service not running";

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "project":"$folder",
       "id":"$ID",
       "machine":"$MACHINE",
       "grp":"node",
       "owner":"$OWNER"
  },
  "fields": {
        "chain":"?",
        "network":"?",
        "version":"$version",
        "status":"$status",
        "message":"$message",
        "service":$service,
        "errors":$errors,
        "url":"",
        "rate-hour":"$rate-hour",
        "rate-day":"$rate-day"
  }
}
EOF

cat $json | jq
