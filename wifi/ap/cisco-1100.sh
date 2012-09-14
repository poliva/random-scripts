#!/bin/sh
# cambiar ip a traves de http automaticamente en Cisco 1100
# (c) 2010 Pau Oliva

USER="username"
PASS="password"

OLDIP="10.45.1.10"
NEWIP="10.4.128.10"
NEWGW="10.4.128.1"
NEWMASK="255.255.252.0"

ping -c1 -w1 $OLDIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$OLDIP ---> NO CONTESTA PING, MISSION ABORTED!!"
        exit 1
fi

# cambiamos DNS
echo "cambio DNS"
curl "http://${USER}:${PASS}@${OLDIP}/no+ip+name-server%5Bconfigure%5D%0Aip+name-server+%24textNameServer1+%24textNameServer2+%24textNameServer3%5Bconfigure%5D%0Awrite+memory+quiet%0A" -d "htmlSubmit=true&radioEnableDns=T&textDefaultDomain=&textNameServer1=${NEWGW}&textNameServer2=&textNameServer3=" -o /dev/null 2>/dev/null

# cambiamos IP y GW
echo "cambio ip y gw"
curl "http://${USER}:${PASS}@${OLDIP}/ip+default-gateway+${NEWGW}%5Bconfigure%5D%0Aip+address+${NEWIP}+${NEWMASK}%5Binterface%2fBVI1%5D%0Awrite+memory+quiet%0A" -d "send=back.htm&SHO_RUN=&SHO_DEFAULT_GATEWAY=&SHO_IP_INT_BRIEF=&SHO_RUN_BV1=&SHO_INT_BV1=&showInt=&radio_dhcp=static&text_ipaddress=${NEWIP}&text_netmask=${NEWMASK}&text_gateway=${NEWGW}" -o /dev/null 2>/dev/null

echo "CAMBIO: $OLDIP --> $NEWIP"
ping -c1 -w2 $OLDIP >/dev/null 2>/dev/null
if [ $? != 1 ]; then
        echo "$OLDIP --> SIGUE CONTESTANDO PING, ALGO FALLA!!"
        exit 1
fi
ping -c1 -w3 $NEWIP >/dev/null 2>/dev/null
if [ $? != 0 ]; then
        echo "$NEWIP ---> NO CONTESTA PING"
        exit 1
fi

