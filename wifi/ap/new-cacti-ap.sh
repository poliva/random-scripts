#!/bin/bash

NEMONICO="$1"
IP="$2"

if [ "$#" != 2 ]; then
	echo "USAGE: $0 <NEMONICO> <IP>"
	exit 1
fi

CACTI="CACTI_IP"
C_USER="CACTI_USER"
C_PASS="CACTI_PASS"

# auth
curl http://${CACTI}/cacti/index.php -d "action=login&login_username=${C_USER}&login_password=${C_PASS}" -c cookies

sleep 1s

# add host
curl -s http://${CACTI}/cacti/host.php -d "description=${NEMONICO}&hostname=${IP}&host_template_id=9&availability_method=2&ping_method=1&ping_port=23&ping_timeout=400&ping_retries=1&snmp_version=1&snmp_community=kubisnmp&snmp_username=&snmp_password=&snmp_password_confirm=&snmp_auth_protocol=MD5&snmp_priv_passphrase=&snmp_priv_protocol=DES&snmp_context=&snmp_port=161&snmp_timeout=500&max_oids=10&notes=&id=0&_host_template_id=0&save_component_host=1&action=save&x=33&y=11" -b cookies

sleep 1s

# list hosts
curl -s "http://${CACTI}/cacti/host.php?host_template_id=9&host_status=-1&filter=&host_rows=5000&x=18&y=11&page=1" -b cookies > hostlist.txt

# get id of the host we added
ID=`cat hostlist.txt |grep "id=.*'>${NEMONICO}</a></td>" |cut -f 7 -d "=" |cut -f 1 -d "'"`

echo "ID: $ID ($NEMONICO - $IP)"
if [ -z "$ID" ]; then
	echo -n "ENTER ID: "
	read ID
fi


sleep 3s
# create 3 graphs for our new host (42 & 36 & 7) 
curl -s http://${CACTI}/cacti/graphs_new.php -d "cg_42=on&cg_36=on&cg_7=on&cg_g=0&save_component_graph=1&host_id=${ID}&host_template_id=9&action=save&x=49&y=12" -b cookies -o /dev/null

sleep 3s
curl -s http://${CACTI}/cacti/graphs_new.php -d "gi_0_7_16_color_id=25&gi_0_7_17_text_format=&host_template_id=9&host_id=${ID}&save_component_new_graphs=1&selected_graphs_array=a%3A1%3A%7Bs%3A2%3A%22cg%22%3Ba%3A3%3A%7Bi%3A42%3Ba%3A1%3A%7Bi%3A42%3Bb%3A1%3B%7Di%3A36%3Ba%3A1%3A%7Bi%3A36%3Bb%3A1%3B%7Di%3A7%3Ba%3A1%3A%7Bi%3A7%3Bb%3A1%3B%7D%7D%7D&action=save&x=61&y=16" -b cookies -o /dev/null

sleep 1s
