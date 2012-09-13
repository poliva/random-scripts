#!/bin/bash
sudo iw dev wlan0 interface add wmon0 type monitor
sudo ifconfig wmon0 up
sudo dumpcap -i wmon0 -w /tmp/wlan0.pcap
