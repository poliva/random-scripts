#!/bin/sh
# cambiar ip automaticamente en linksys WAP200
# (c) 2009 Pau Oliva

USER="admin"
PASS="admin"

OLDIP="10.3.192.4"
NEWIP="10.3.192.3"
NEWMASK="255.255.252.0"
NEWGW="10.3.192.1"

### no tocar a partir de aqui
rm setup.txt 2>/dev/null
rm result.txt 2>/dev/null
ping -c1 -w1 $OLDIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$OLDIP ---> NO CONTESTA PING, MISSION ABORTED!!"
        exit 1
fi

curl -m 30 http://${USER}:${PASS}@${OLDIP}/SetupLanTypeStatic.htm > setup1.txt 2>/dev/null
curl -m 30 http://${USER}:${PASS}@${OLDIP}/Setup.htm >> setup2.txt 2>/dev/null
HOSTNAME=`cat setup2.txt |grep "passForm.hostname.value" |grep -v "''" |grep -v "\/\/p" |cut -f 2 -d "'" |head -n 1`
lan_ipaddr=`cat setup1.txt |grep "SplitLanIPAddress" |grep "static" |cut -f 2 -d "'"`
if [ "$lan_ipaddr" != "$OLDIP" ]; then
        echo "ERROR: $lan_ipaddr != $OLDIP"
        exit 1
fi
lan_netmask=`cat setup1.txt |grep "SplitLanSubnetMask" |grep "static" |cut -f 2 -d "'" |head -n 1`
nameserver2=`cat setup1.txt |grep "SplitLanSecDNS" |grep "name_server" |cut -f 2 -d "'" |head -n 1`
curl -m 30 http://${USER}:${PASS}@${OLDIP}/apply.cgi -d "page=Setup.htm&hostname=${HOSTNAME}&device_name=&lan_mode=1&lan_ipaddr=${NEWIP}&lan_netmask=${NEWMASK}&lan_gateway=${NEWGW}&lan_prim_dns=${NEWGW}&lan_sec_dns=${nameserver2}&is_dns_neg=0&default_route=1" > result.txt 2>/dev/null
cat result.txt |grep "System Restart" |sed -e "s/<p>/\n/g" |grep "System Restart"
if [ $? != 0 ]; then
        echo "ERROR: see result.txt"
        exit 1
fi
rm setup.txt 2>/dev/null
rm setup1.txt 2>/dev/null
rm setup2.txt 2>/dev/null
rm result.txt 2>/dev/null
echo "CAMBIO: $OLDIP --> $NEWIP"
sleep 15s
ping -c1 -w2 $OLDIP >/dev/null 2>/dev/null
if [ $? != 1 ]; then
        echo "$OLDIP --> SIGUE CONTESTANDO PING, ALGO FALLA!!"
        exit 1
fi
sleep 2s
ping -c1 -w6 $NEWIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$NEWIP ---> NO CONTESTA PING"
        exit 1
fi
