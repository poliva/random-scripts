#!/bin/bash

IFACE="eth0"
SLEEP_T=20

# Sample 1
t1=`date +%s`
ifconfig $IFACE > /tmp/sample1
t2=`date +%s`

sleep $SLEEP_T

# Sample 2
t3=`date +%s`
ifconfig $IFACE > /tmp/sample2
t4=`date +%s`

td=$(( ( ($t4 - $t2) + ($t3 - $t1) ) / 2 ))

# RX
pre=`cat /tmp/sample1 |grep "RX bytes" |cut -f 2 -d ":" |cut -f 1 -d " "`
post=`cat /tmp/sample2 |grep "RX bytes" |cut -f 2 -d ":" |cut -f 1 -d " "`
calc="(${post} - ${pre})/${td}*8/1024"
res=$((${calc}))
res2=$(($res /1024))
echo "DOWN: ${res} kbit/s - ${res2} Mbps"

# TX
pre=`cat /tmp/sample1 |grep "TX bytes" |cut -f 3 -d ":" |cut -f 1 -d " "`
post=`cat /tmp/sample2 |grep "TX bytes" |cut -f 3 -d ":" |cut -f 1 -d " "`
calc="(${post} - ${pre})/${td}*8/1024"
res=$((${calc}))
res2=$(($res /1024))
echo "UP: ${res} kbit/s - ${res2} Mbps"

rm /tmp/sample1 /tmp/sample2

