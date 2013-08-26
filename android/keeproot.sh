#!/system/bin/sh
#
# OTA "root keeper" for Android 4.3+
# 
# install instructions:
#  0) if you have SuperSU: chattr -i /system/etc/install-recovery.sh, otherwise OTA will fail
#  1) copy this script to /system/xbin/keeproot.sh and make it executable.
#  2) rm /system/bin/log && ln -s /system/xbin/keeproot.sh /system/bin/log
#   

if [ "$2" == "recovery" ]; then
	if [ ! -u /system/xbin/su ]; then

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
		EOF

		mount -o remount,ro /system
	fi
fi
toolbox log ${1+"$@"}
