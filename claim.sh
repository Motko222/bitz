#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source $path/env

cd /root/.cargo/bin/bitz
[ -z $1 ] && ./bitz claim -p $POOL || echo y | ./bitz claim -p $POOL
