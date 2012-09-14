#!/bin/sh
# cambiar ip automaticamente en linksys WAP2000
# (c) 2009 Pau Oliva

USER="admin"
PASS="admin"
OLDIP="10.27.1.5"

NEWIP="10.27.1.4"
NEWMASK="255.255.0.0"
NEWGW="10.27.1.1"

### no tocar a partir de aqui
rm setup.txt >/dev/null
rm result.txt >/dev/null
ping -c1 -w1 $OLDIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$OLDIP ---> NO CONTESTA PING, MISSION ABORTED!!"
        exit 1
fi
curl http://${USER}:${PASS}@${OLDIP}/Setup.htm > setup.txt
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
curl http://${USER}:${PASS}@${OLDIP}/apply.cgi -d "page=index.htm&hostname=${HOSTNAME}&device_name=&lan_mode=1&lan_ipaddr=${NEWIP}&lan_netmask=${NEWMASK}&lan_gateway=${NEWGW}&lan_prim_dns=${NEWGW}&lan_sec_dns=${nameserver2}&is_dns_neg=0&default_route=1&SYSName=${SYSNAME}&SYSContact=${SYSCONTACT}&SYSLocation=${SYSLOCATION}" > result.txt ; echo
cat result.txt |grep "System Restart" |sed -e "s/<p>/\n/g" |grep "System Restart"
if [ $? != 0 ]; then
        echo "ERROR: see result.txt"
        exit 1
fi
rm setup.txt
rm result.txt
echo "CAMBIO: $OLDIP --> $NEWIP"
ping -c1 -w1 $NEWIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$NEWIP ---> NO CONTESTA PING"
        exit 1
fi

