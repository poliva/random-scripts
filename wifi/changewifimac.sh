#!/bin/bash
REALMAC=xx:xx:xx:xx:xx:xx

sudo ifconfig wlan0 down
if [ "$1" == "-r" ]; then
	sudo macchanger -m $REALMAC wlan0
else
	sudo macchanger -e wlan0
fi
sudo dhclient3 wlan0
ifconfig wlan0
