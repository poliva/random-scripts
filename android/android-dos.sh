# find crashes in Android debugfs - should work on standard android with toolbox
# (c) 2012 Pau Oliva Fora - viaForensics
#
# run: android-dos.sh /sys/kernel/debug
# after you get a reboot/crash, add it as a parameter to exclude it on the next run:
# android-dos.sh /sys/kernel/debug exclude1 exclude2, etc...

l=$1/*
shift
s=$*
for g in $l ; do
        if [ -z "$s" ]; then s=NoNeXiStEnT ; fi
        if [ -d "$g" ]; then $0 "$g" $s ; fi
        f=0
        for n in $s ; do
                echo "$g" |grep -v "$n" >/dev/null
                if [ "$?" -eq "1" ]; then f=1 ; fi
        done
        if [ $f -eq 0 ]; then
                echo $g
                cat "$g" >/dev/null 2>&1
        else
                echo "================= skipping $g"
        fi
done
