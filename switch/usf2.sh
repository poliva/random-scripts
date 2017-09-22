#!/bin/bash

SWITCH="192.168.x.x"

NC="\033[0m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
MARK="\033[1;37m"
GRAY="\033[1;30m"

LAST=''
IPS2=''
repeat=0
ban=0

printf " ${GRAY}-------------------------${NC}\n"
printf "${GRAY}>${NC} Nintendo Switch Latency Monitor v0.1\n"
printf "${GRAY}>${NC} (c) 2017 Pau Oliva Fora - ${MARK}@pof${NC}\n"
printf " ${GRAY}-------------------------${NC}\n"

sudo echo -n ''

case $1 in
	"-b") ban=1 ;;    # play only europe
	"-c") ban=200 ;;  # play only ping < 200
	"-r")
		# clear bans
		echo "Cleaning bans..."
		for f in `sudo iptables -n -L FORWARD |grep -i DROP |awk '{print $4}' |grep -vi "DROP"` ; do echo "Clean $f - OK"; sudo iptables -D FORWARD -j DROP -s $f ; done
		rm -rf /tmp/usf2ban.txt 2>/dev/null
		echo "Done!"
		exit 0
	;;
	"-k")
		echo "Banning known users..."
		cat /home/pau/bin/knonw-users.txt |cut -f 1 -d " "| xargs -n 1 sudo iptables -I FORWARD -j DROP -s
		exit 0
	;;
esac

rm /tmp/usf2last.txt /tmp/usf2ips.txt /tmp/usf2diff.txt 2>/dev/null

while true ; do
	IPS=$(sudo tac /proc/net/ip_conntrack |grep "^udp.*${SWITCH}.*ASSURED" |grep -v "dport=53 " |awk '{print $5}' |sed -e "s/^dst=//g" |awk -vORS=" " '!x[$0]++')
	#IPS=$(sudo tac /proc/net/ip_conntrack |grep "udp.*ASSURED" |awk '{print $5}' |sed -e "s/^dst=//g" |awk -vORS=" " '!x[$0]++')

	# filter out amazon ips (nintendo infra)
	IPS3=''
	for ip in ${IPS} ; do
		dig +short -x ${ip} |grep "\.amazonaws\.com.$" >/dev/null
		if [ "$?" -ne 0 ]; then
			IPS3="$IPS3 $ip"
		fi
	done
	IPS=$(echo $IPS3 |sed -e "s/^ //g")

	if [ -z "${IPS}" ]; then
		sleep 1s
		continue
	fi

	echo $LAST |sed -e "s: :\n:g" |sort -u >/tmp/usf2last.txt
	echo $IPS |sed -e "s: :\n:g" |sort -u >/tmp/usf2ips.txt

	echo "$LAST" |grep "^${IPS}$" >/dev/null
	if [ $? -eq 0 ]; then
		repeat=$(( $repeat + 1 ))
		LAST=$IPS
	else
		repeat=0
		diff /tmp/usf2last.txt /tmp/usf2ips.txt > /tmp/usf2diff.txt
		IPS2=$(cat /tmp/usf2diff.txt |grep ">" |awk '{print $2}')
	fi

	LAST=$IPS
	if [ "$repeat" -ge 3 ]; then continue ; fi

	IPS=$(echo "${IPS2} ${IPS}" |sed -e "s: :\n:g" |awk -vORS=" " '!x[$0]++')

	for ip in ${IPS} ; do

		new=0
		cat /tmp/usf2diff.txt |grep "> ${ip}$" >/dev/null 2>/dev/null
		if [ $? -eq 0 ]; then
			new=1
			MARK="\033[1;37m"
		else
			MARK=""
		fi

		iplen=$(echo $ip |wc -c)
		spaces=$(( 16 - $iplen ))
		printf "> ${MARK}${ip}${NC} "
		for f in `seq 1 $spaces` ; do
			printf " "
		done
		printf -- "- "
		country=$(geoip.py ${ip} 2>/dev/null)
		if [ -z "$country" ]; then country="[ xx ] Unknown (Unknown)" ; fi
		printf "$country - "

		if [ "$ban" -eq 1 ]; then
			echo "$country" |egrep "(Europe|Unknown)" >/dev/null
			if [ $? -ne 0 ]; then
				cat /tmp/usf2ban.txt 2>/dev/null |grep "^${ip}$" >/dev/null
				if [ $? -ne 0 ]; then
					dig +short -x ${ip} |grep -i "\.amazonaws\.com.$" >/dev/null
					if [ "$?" -ne 0 ]; then
						echo "$ip" >> /tmp/usf2ban.txt
						sudo iptables -I FORWARD -j DROP -s ${ip}
						printf "[${RED}BAN!${NC}] "
					else
						printf "(${YELLOW}!!!${NC} ${MARK}AMAZON${NC} ${YELLOW}!!!${NC}) - "
					fi
				else
						printf "[${RED}BANED${NC}] "
				fi
			fi
		fi

		res=$(ping -nq -c1 -W1 ${ip} |grep "^rtt" |awk '{print $4}' |cut -f 2 -d "/")
		if [ -z "${res}" ]; then
			res=$(traceroute -n -q 1 -w 0.4 -N 16 -m 16 ${ip} |grep " ms$" |rev |cut -f 2 -d " " |rev |cut -f 1 -d "." |sort -nr |head -n 1)
		fi

		res=$(echo -n "$res" |cut -f 1 -d "." |egrep -o "[0-9]+")

		if [ "$ban" -eq 200 ]; then
			if [ $res -ge 200 ]; then
				cat /tmp/usf2ban.txt 2>/dev/null |grep "^${ip}$" >/dev/null
				if [ $? -ne 0 ]; then
					dig +short -x ${ip} |grep -i "\.amazonaws\.com.$" >/dev/null
					if [ "$?" -ne 0 ]; then
						echo "$ip" >> /tmp/usf2ban.txt
						sudo iptables -I FORWARD -j DROP -s ${ip}
						printf "[${RED}BAN!${NC}] "
					else
						printf "(${YELLOW}!!!${NC} ${MARK}AMAZON${NC} ${YELLOW}!!!${NC}) - "
					fi
				else
						printf "[${RED}BANED${NC}] "
				fi
			fi
		fi

		if [ $res -le 100 ]; then
			printf "${GREEN}${res} ms${NC}\n"
		elif [ $res -le 140 ]; then
			printf "${YELLOW}${res} ms${NC}\n"
		else
			printf "${RED}${res} ms${NC}\n"
		fi

	done

	GONE=$(cat /tmp/usf2diff.txt |grep "<" |awk '{print $2}' 2>/dev/null)
	for ip2 in ${GONE}; do

		iplen=$(echo $ip2 |wc -c)
		spaces=$(( 16 - $iplen ))
		printf "< ${GRAY}${ip2}${NC} "
		for f in `seq 1 $spaces` ; do
			printf " "
		done
		printf -- "- "
		country=$(geoip.py ${ip2} 2>/dev/null)
		if [ -z "$country" ]; then country="[ xx ] Unknown (Unknown)" ; fi
		printf "${GRAY}${country}${NC}\n"
	done

	printf " ${GRAY}-------------------------${NC}\n"
done
