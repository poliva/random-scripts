#!/bin/bash
#
# Generic Load balancer for multiple WAN links - version 1.1 (04 Feb 2011)
# (c) 2011 Pau Oliva Fora - http://pof.eslack.org
#
# Licensed under GPLv3 - for full terms see:
# http://www.gnu.org/licenses/gpl-3.0.html
#
#
# Specify each WAN link in a separate column, example:
#
# In this example we have 3 wan links (vlanXXX interfaces) attached to a single
# physical interface because we use a vlan-enabled switch between the balancer
# machine and the ADSL routers we want to balance. The weight parameter should
# be kept to a low integer, in this case the ADSL line connected to vlan101 and
# vlan102 is 4Mbps and the ADSL line connected to vlan100 is 8Mbps (twice fast)
# so the WEIGHT value in vlan100 is 2 because it is two times faster.
#
# WANIFACE="	vlan101		vlan100		vlan102"
# GATEWAYS="	192.168.1.1	192.168.0.1	192.168.2.1"
# NETWORKS="	192.168.1.0/24	192.168.0.0/24	192.168.2.0/24"
# WEIGHTS="	1 		2		1"
#
# quick formula to calculate the weight: (LINKSPEED/MINSPEED)*NUM_LINKS
#
# If you don't want to use vlans, you should then use a separate physical
# interface for each link. IP aliasing on the same interface is not supported.
#

WANIFACE="   usb0            usb1              "
GATEWAYS="   192.168.43.129  192.168.42.129      "
NETWORKS="   192.168.43.0/24 192.168.42.0/24   "
WEIGHTS="    2               1                  "

# enable link failover watchdog? set to "yes" or "no".
WATCHDOG="yes"

# space separated list of public IPs to ping in watchdog mode
# set this to some public ip addresses pingable and always on.
TESTIPS="8.8.8.8 192.0.32.10"

# set to 1 when testing, set to 0 when happy with the results
VERBOSE=1

# CONFIGURATION ENDS HERE
# do not modify below this line unless you know what you're doing :)

function getvalue() {
        index=$1
        VAR=$2

        n=1
        for f in ${VAR} ; do
                if [ "${n}" == "${index}" ]; then
                        echo "$f"
                        break
                fi
                n=$(($n + 1))
        done
}

echo "[] Load balancer for multiple WAN interfaces - v1.1"
echo "[] (c) 2011 Pau Oliva Fora <pof> @eslack.org"
echo

case $1 in
	start) PARAM="add" ;;
	stop) PARAM="del" ;;
	*) echo "Usage: $0 [start|stop]" ; echo ; exit 1 ;;
esac

if [ $(whoami) != "root" ]; then
        echo "You must be root to run this!" ; echo ; exit 1
fi

routecmd="ip route replace default scope global"

i=1
for iface in $WANIFACE  ; do

	IP=`ifconfig $iface |grep "inet addr" |cut -f 2 -d ":" |awk '{print $1}'`
	NET=$(getvalue $i "$NETWORKS")
	GW=$(getvalue $i "$GATEWAYS")
	WT=$(getvalue $i "$WEIGHTS")

	echo "[] Interface: ${iface}"
	if [ $VERBOSE -eq 1 ]; then
		echo "	IP: ${IP}"
		echo "	NET: ${NET}"
		echo "	GW: ${GW}"
		echo "	Weight: ${WT}"
		echo
	fi
	set -x
	ip route ${PARAM} ${NET} dev ${iface} src ${IP} table ${i}
	ip route ${PARAM} default via ${GW} table ${i}
	ip rule ${PARAM} from ${IP} table ${i}
	set +x
	echo
	routecmd="${routecmd} nexthop via ${GW} dev ${iface} weight ${WT}"
	i=$(($i + 1))
done

echo "[] Balanced routing:"

set -x
${routecmd}
set +x
echo

if [ $PARAM == "del" ] || [ $WATCHDOG != "yes" ]; then
	exit 0
fi

echo "[] Watchdog started"
# 0 == all links ok, 1 == some link down
STATE=0

while : ; do

	if [ $VERBOSE -eq 1 ]; then
		echo "[`date '+%H:%M:%S'`] Sleeping, state=$STATE"
	fi
	sleep 30s

	IFINDEX=1
	DOWN=""
	DOWNCOUNT=0
	for iface in $WANIFACE ; do

		FAIL=0
		COUNT=0
		IP=`ifconfig $iface |grep "inet addr" |cut -f 2 -d ":" |awk '{print $1}'`
		for TESTIP in $TESTIPS ; do
			COUNT=$(($COUNT + 1))
			ping -W 3 -I $IP -c 1 $TESTIP > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				FAIL=$(($FAIL + 1))
			fi
		done
		if [ $FAIL -eq $COUNT ]; then
			echo "[`date '+%H:%M:%S'` WARN] $iface is down!"
			if [ $STATE -ne 1 ]; then
				echo "Switching state $STATE -> 1"
				STATE=1
			fi
			DOWN="${DOWN} $IFINDEX"
			DOWNCOUNT=$(($DOWNCOUNT + 1))
		fi
		IFINDEX=$(($IFINDEX + 1))
	done

	if [ $DOWNCOUNT -eq 0 ]; then
		if [ $STATE -eq 1 ]; then
			echo
			echo "[`date '+%H:%M:%S'`] All links up and running :)"
			if [ $VERBOSE -eq 1 ]; then
				set -x
				${routecmd}
				set +x
				echo
			else
				${routecmd} 2>/dev/null
			fi
			STATE=0
			echo "Switching state 1 -> 0"
		fi
		# if no interface is down, go to the next cycle
		continue
	fi

	cmd="ip route replace default scope global"

	IFINDEX=1
	for iface in $WANIFACE ; do
		for lnkdwn in $DOWN ; do
			if [ $lnkdwn -ne $IFINDEX ]; then
				GW=$(getvalue $IFINDEX "$GATEWAYS")
				WT=$(getvalue $IFINDEX "$WEIGHTS")
				cmd="${cmd} nexthop via ${GW} dev ${iface} weight ${WT}"
			fi
		done
		IFINDEX=$(($IFINDEX + 1))
	done

	if [ $VERBOSE -eq 1 ]; then
		set -x
		${cmd}
		set +x
		echo
	else
		${cmd} 2>/dev/null
	fi
done
