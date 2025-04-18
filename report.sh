#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$(bitz -V | awk '{print $NF}')
service=$(sudo systemctl status $folder --no-pager | grep "active (running)" | wc -l)
errors=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")
#rate_hour=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {printf "%0.2f",sum}')
#rate_day=$(journalctl -u $folder.service --since "1 day ago" --no-hostname -o cat | grep -E "Confirmed" | awk '{print $6}' | sed 's/\./,/g' | awk '{sum+=$1} END {printf "%0.2f",sum}')
bitz account >/root/logs/bitz-account

miner_balance=$(cat /root/logs/bitz-account | grep Balance | tail -1 | awk '{print $2}')

status="ok" && message="bal $miner_balance"
[ $errors -gt 500 ] && status="warning" && message="errors=$errors";
[ $service -ne 1 ] && status="error" && message="service not running";

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "id":"$folder-$ID",
       "grp":"node",
       "machine":"$MACHINE",
       "owner":"$OWNER"
  },
  "fields": {
        "chain":"eclipse",
        "network":"mainnet",
        "version":"$version",
        "status":"$status",
        "message":"$message",
        "service":$service,
        "errors":$errors,
        "url":"",
        "miner_balance":"$miner_balance"
  }
}
EOF

cat $json | jq
