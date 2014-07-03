#!/bin/bash
# check latency without using ping, we take the RTT of the worst hop

ip=$1
if [ -z ${ip} ]; then
	echo "Usage: `basename $0` <ip>"
	exit 1
fi

traceroute -n -q 1 -w 0.3 -N 1 -m 20 ${ip} |grep " ms$" |rev |cut -f 2 -d " " |rev |cut -f 1 -d "." |sort -nr |head -n 1
