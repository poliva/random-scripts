#!/bin/bash
case "$1" in
	"wl")
		echo "Using wifi driver wl"
		sudo rmmod brcmsmac mac80211 brcmutil cfg80211 crc8 cordic
		sudo modprobe wl
		sudo modprobe cfg80211
		sudo modprobe mac80211
	;;
	"brcmsmac")
		echo "brcmsmac"
		sudo rmmod wl
		sudo modprobe brcmsmac
	;;
	*)
		echo "USAGE: $0 [wl|brcmsmac]"
		exit 1
esac
