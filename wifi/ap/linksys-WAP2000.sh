#!/bin/sh
# cambiar ip automaticamente en linksys WAP2000
# (c) 2009 Pau Oliva

USER="admin"
PASS="admin"

OLDIP="10.3.192.3"
NEWIP="10.3.192.4"
NEWMASK="255.255.252.0"
NEWGW="10.3.192.1"

rm setup.txt 2>/dev/null
rm result.txt 2>/dev/null
ping -c1 -w1 $OLDIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$OLDIP ---> NO CONTESTA PING, MISSION ABORTED!!"
        exit 1
fi

#curl http://${USER}:${PASS}@${OLDIP}/SetupLanTypeStatic.htm > setup.txt
curl -m 30 http://${USER}:${PASS}@${OLDIP}/Setup.htm >> setup.txt 2>/dev/null
HOSTNAME=`cat setup.txt |grep "passForm.hostname.value" |grep -v "''" |grep -v "\/\/p" |cut -f 2 -d "'"`
SYSNAME=`cat setup.txt |grep "passForm.SYSName.value" |grep -v "''" |grep -v "\/\/p" |cut -f 2 -d "'"`
SYSCONTACT=`cat setup.txt |grep "passForm.SYSContact.value" |grep -v "''" |grep -v "\/\/p" |cut -f 2 -d "'"`
SYSLOCATION=`cat setup.txt |grep "passForm.SYSLocation.value" |grep -v "''" |grep -v "\/\/p" |cut -f 2 -d "'"`
lan_mode=`head -n 30 setup.txt |grep "^var lan_mode" |cut -f 2 -d "'"`
if [ "$lan_mode" != "1" ]; then
        echo "ERROR: Lan mode ($lan_mode)no es IP statica!"
        exit 1
fi
lan_ipaddr=`cat setup.txt |grep "SplitLanIPAddress" |grep "static" |cut -f 2 -d "'"`
if [ "$lan_ipaddr" != "$OLDIP" ]; then
        echo "ERROR: $lan_ipaddr != $OLDIP"
        exit 1
fi
lan_netmask=`cat setup.txt |grep "SplitLanSubnetMask" |grep "static" |cut -f 2 -d "'"`
#lan_gateway=`cat setup.txt |grep "SplitLanGateway" |grep "static" |cut -f 2 -d "'"`
#nameserver1=`cat setup.txt |grep "SplitLanPrimDNS" |grep "name_server" |cut -f 2 -d "'"`
nameserver2=`cat setup.txt |grep "SplitLanSecDNS" |grep "name_server" |cut -f 2 -d "'"`
curl -m 30 http://${USER}:${PASS}@${OLDIP}/apply.cgi -d "page=index.htm&hostname=${HOSTNAME}&device_name=&lan_mode=1&lan_ipaddr=${NEWIP}&lan_netmask=${NEWMASK}&lan_gateway=${NEWGW}&lan_prim_dns=${NEWGW}&lan_sec_dns=${nameserver2}&is_dns_neg=0&default_route=1&SYSName=${SYSNAME}&SYSContact=${SYSCONTACT}&SYSLocation=${SYSLOCATION}" > result.txt 2>/dev/null
cat result.txt |grep "System Restart" |sed -e "s/<p>/\n/g" |grep "System Restart"
if [ $? != 0 ]; then
        echo "ERROR: see result.txt"
        exit 1
fi
rm setup.txt 2>/dev/null
rm result.txt 2>/dev/null
echo "CAMBIO: $OLDIP --> $NEWIP"
sleep 15s
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
