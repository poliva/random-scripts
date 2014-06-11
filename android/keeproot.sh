#!/system/bin/sh
#
# OTA "root keeper" for Android 4.3+
#
#  - if you have (old) SuperSU: chattr -i /system/etc/install-recovery.sh, otherwise OTA will fail
#  - if you have SuperSU pro, don't use this script. Use SuperSU OTA Survival feature.
# 
# install instructions:
#  1) copy this script to /system/xbin/keeproot.sh and make it executable.
#  2) rm /system/bin/log && ln -s /system/xbin/keeproot.sh /system/bin/log
#   

if [ "$2" == "recovery" ]; then
	grep "daemon" /system/etc/install-recovery.sh >/dev/null 2>/dev/null
	if [ $? -eq 1 ]; then

		mount -o remount,rw /system

		chown root.root /system/xbin/su
		chmod 6755 /system/xbin/su

		chown root.root /system/xbin/daemonsu 2>/dev/null
		chmod 6755 /system/xbin/daemonsu 2>/dev/null

		cat >>/system/etc/install-recovery.sh <<-EOF 
# koush SuperUser
/system/xbin/su --daemon &
# Chainfire SuperSU
/system/xbin/daemonsu --auto-daemon &
/system/etc/install-recovery-2.sh
		EOF

		mount -o remount,ro /system

		grep "daemon" /system/etc/install-recovery.sh >/dev/null 2>/dev/null
		if [ $? -eq 0 ]; then
			/system/etc/install-recovery.sh >/dev/null 2>/dev/null &
		fi
	fi
fi
toolbox log ${1+"$@"}
