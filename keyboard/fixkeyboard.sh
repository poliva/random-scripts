#!/bin/bash
# for some reason my usb keyboard misses the first 1 or 2 keystrokes after
# when it resumes after being idle for a while. The bug is caused by usb
# autosuspend, but i don't want to fully disable it on my laptop, so here's
# the workaround to only disable autosuspend on the USB port where the
# keyboard is connected.

DEVICE="046a:0010"

# make sure this is run as root
uid=$(id -ur)
if [ "$uid" != "0" ]; then
	echo "This script must be run as root"
	exit 1
fi

busnum=$(lsusb |grep "${DEVICE}" |cut -f 2 -d " ")
devnum=$(lsusb |grep "${DEVICE}" |cut -f 4 -d " " |sed -e "s/://")

if [ -z $devnum ]; then
	echo "Keyboard not found"
	exit 1
fi

for f in `ls /sys/bus/usb/devices/ |grep -v ":"` ; do
	BUSNUM=$(cat /sys/bus/usb/devices/$f/busnum)
	DEVNUM=$(cat /sys/bus/usb/devices/$f/devnum)
	if [ "$BUSNUM" -eq "$busnum" ] && [ "$DEVNUM" -eq "$devnum" ]; then
		break
	fi
done

echo "Disabling autosuspend on USB $BUSNUM:$DEVNUM, to reenable:"
echo "echo 2 |sudo tee /sys/bus/usb/devices/$f/power/autosuspend"
echo -1 > /sys/bus/usb/devices/$f/power/autosuspend
