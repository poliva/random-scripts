#!/bin/sh
IP=$1

COMMUNITY="public"
USER="user"
PASS="pass"

OID="system.sysUpTime.0"

echo "Test1"
snmpget -t 2 -r 3 -On -v1 -c $COMMUNITY $IP $OID
echo "Test2"
snmpget -v2c -c $COMMUNITY $IP $OID
echo "Test3"
snmpget -Oqv -lauthNoPriv -u $USER -A $PASS $IP $OID
echo "Done!"
