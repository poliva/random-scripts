#!/system/bin/sh
#
# change wifi MAC address on Nexus 4.
# The original MAC address will be restored upon reboot.
#
# - Needs radare2 & busybox installed
# (c) 2013 Pau Oliva (@pof)

mymac=`ip addr show wlan0 |grep link/ether |grep link/ether |awk '{print $2}' |sed -e "s/://g"`
newmac=`echo $1 |sed -e "s/://g"`

len=`echo -n ${mymac} |wc -c`
if [ "$len" != "12" ]; then
	echo "ERROR: is busybox installed?"
	exit 1
fi

len=`echo -n ${newmac} |wc -c`
if [ "$len" != "12" ]; then
	echo "Usage: $0 <12-hex-digit-MAC-address>"
	exit 1
fi

sed -i "s/${mymac}/${newmac}/gI" /data/misc/wifi/WCNSS_qcom_cfg.ini
/data/data/org.radare.installer/radare2/bin/r2 -c "wx ${newmac}@0xa" -n -q -w /data/misc/wifi/WCNSS_qcom_wlan_nv.bin
