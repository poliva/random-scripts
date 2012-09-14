#!/bin/sh
# cambiar ip via http automaticamente en Cisco 350 vxworks
# (c) 2010 Pau Oliva

USER="username"
PASS="password"

OLDIP="10.0.0.10"
NEWIP="10.22.0.10"
NEWMASK="255.255.255.0"
NEWGW="10.22.0.1"

ping -c1 -w1 $OLDIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$OLDIP ---> NO CONTESTA PING, MISSION ABORTED!!"
        exit 1
fi

curl "http://${USER}:${PASS}@${OLDIP}/Setup.shm" -D header1 > tmpfile 2>/dev/null
URL1=`cat tmpfile  |grep "Express&nbsp;Setup" |cut -f 2 -d \"`
rm tmpfile

curl "http://${USER}:${PASS}@${OLDIP}/${URL1}" -D header2 -e "http://${USER}:${PASS}@${OLDIP}/Setup.shm" > tmpfile 2>/dev/null
URL2=`cat tmpfile |grep "^action=" |cut -f 2 -d \"`

text_sysName=`cat tmpfile |grep "text_sysName" |cut -f 4 -d \"`
ssid=`cat tmpfile |grep text_dot11DesiredSSID.2 |cut -f 4 -d \"`
snmp=`cat tmpfile |grep "text_SNMPAdminCommunity" |cut -f 6 -d \"`

curl "http://${USER}:${PASS}@${OLDIP}${URL2}" -D header3 -e "http://${USER}:${PASS}@${OLDIP}/${URL1}" -d "text_sysName=${text_sysName}&select_bootconfigBootProtocol=1&text_awcIfDefaultIpAddress.1=${NEWIP}&text_awcIfDefaultIpNetMask.1=${NEWMASK}&text_ipRouteNextHop.0.0.0.0=${NEWGW}&text_dot11DesiredSSID.2=${ssid}&select_SetExpressNetworkRole=4&radio_optimizeRadio=R&default_awcDot11Compatible4500.2=F&default_awcDot11UseAWCExtensions.2=T&text_SNMPAdminCommunity=${snmp}&OK=%A0%A0OK%A0%A0" -o /dev/null 2>/dev/null

rm tmpfile 2>/dev/null
rm header1 2>/dev/null
rm header2 2>/dev/null
rm header3 2>/dev/null
echo "CAMBIO: $OLDIP --> $NEWIP"
sleep 5s
ping -c1 -w2 $OLDIP >/dev/null 2>/dev/null
if [ $? != 1 ]; then
        echo "$OLDIP --> SIGUE CONTESTANDO PING, ALGO FALLA!!"
        exit 1
fi
ping -c1 -w5 $NEWIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$NEWIP ---> NO CONTESTA PING"
        exit 1
fi

