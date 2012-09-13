#!/bin/bash
mount |grep "Volume_2" 2>&1 >/dev/null
if [ "$?" == "1" ]; then
	echo -n "NAS Volume 2 not mounted, mount it?"
	read pause
	mount.cifs //nas/Volume_2 /mnt/
	if [ $? == 0 ]; then
		echo "Mounted ok, press any key to continue"
		read pause
	else
		echo "ERROR"
		exit 1
	fi
fi

SRC="/mnt/media/Finished/WII-pof/TODO"
TMPF="/tmp/wiirarfiles.$$"
TMPF2="/tmp/wiirarfiles-iso.$$"

find $SRC -iname "*.rar" |grep -v "part[0-9]"  > $TMPF
find $SRC -iname "*.rar" |grep "part01.rar"  >> $TMPF
find $SRC -iname "*.rar" |grep "part001.rar"  >> $TMPF
len=`cat $TMPF |wc -l`
find $SRC -iname "*.iso" > $TMPF2
len2=`cat $TMPF2 |wc -l`

lenshow=$(($len + $len2))

echo -n "Process $lenshow files?"
read pause

# rar
for f in `seq 1 $len` ; do
	file=`cat $TMPF |head -n $f |tail -n 1`
	echo "[ $f / $lenshow ] - $file"
	mkdir "$f"
	cd "$f"
	time unrar x -idc "$file"
	rm *.url *.txt *.URL *.TXT 2> /dev/null
	iso=`find . -iname "*.iso"`
	wwt -a ADD "$iso"
	cd ..
	rm -r "$f"
	echo "**** DONE ****"
done

#iso
for f in `seq 1 $len2` ; do
	n=$(($f + $len))
	file=`cat $TMPF2 |head -n $f |tail -n 1`
	echo "[ $n / $lenshow ] - $file"
	wwt -a ADD "$file"
	echo "**** DONE ****"
done


