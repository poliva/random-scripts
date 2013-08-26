#!/system/bin/sh

# for nexus7 (2012) only.
# see: http://forum.xda-developers.com/showthread.php?t=2068207

case $1 in
        "lock")
                echo "[x] Locking bootloader..."
                echo 0 > /sys/block/mmcblk0boot0/force_ro
                dd if=/system/usr/bootunlock/locked-mmcblk0boot0.img of=/dev/block/mmcblk0boot0
                echo 1 > /sys/block/mmcblk0boot0/force_ro
                echo "[x] Bootloader locked!"

        ;;
        "unlock")
                echo "[x] Unlocking bootloader..."
                echo 0 > /sys/block/mmcblk0boot0/force_ro
                dd if=/system/usr/bootunlock/unlocked-mmcblk0boot0.img of=/dev/block/mmcblk0boot0
                echo 1 > /sys/block/mmcblk0boot0/force_ro
                echo "[x] Bootloader unlocked!"
        ;;
        *)
                echo "Usage: $0 <lock|unlock>"
                exit 1
        ;;
esac
