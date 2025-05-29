  GNU nano 6.2                                                                                                                                     /root/scripts/bitz/report.sh                                                                                                                                              
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
echo n | bitz claim -p $POOL >>/root/logs/bitz-account


miner_balance=$(cat /root/logs/bitz-account | grep "Balance" | tail -1 | awk '{print $2}')
pool_balance=$(cat /root/logs/bitz-account | grep "You are about to claim" | tail -1 | awk '{print $6}')

status="ok" && message="bal $pool_balance"
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
        "service":"$service",
        "errors":"$errors",
        "url":"",
        "score1":"$pool_balance (pool)",
        "score2":"$miner_balance (miner)"
  }
}
EOF

cat $json | jq
