#!/bin/bash

if [ "$1" == "-u" ]; then
	echo "umounting /home/pau/android"
	fusermount -u /home/pau/android
	adb kill-server 2>/dev/null
	exit 0
fi

if [ "$1" == "-a" ]; then
	echo "mounting /home/pau/android via adbfs"
	adbfs /home/pau/android/ -o modules=subdir -o subdir=/mnt/sdcard/
	exit $?
fi

#needs aptitude install mtpfs
echo "mounting /home/pau/android via mtpfs"
mount.mtpfs /home/pau/android/
exit $?
