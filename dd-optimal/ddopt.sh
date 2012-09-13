#!/bin/bash
#
# find optimal bs size for 'dd' command.
# taken from http://serverfault.com/questions/147935/how-to-determine-the-best-byte-size-for-the-dd-command
#

if [ -z "$1" ]; then
	echo "Usage: $0 <device>"
	echo "Example: $0 /dev/sdc"
	exit 1
fi

echo "!!! WARNING WARNING WARNING WARNING WARNING !!!"
echo "This will completely WIPE the contents of $1"
echo -n "Type 'yes' to continue: "
read answer

if [ "$answer" != "yes" ]; then
	echo ""
	exit 1
fi

echo "creating a temp file to work with"
dd if=/dev/zero of=/var/tmp/infile count=1175000

for bs in  1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1M 2M 4M 8M 

do
        echo
        echo
        echo "Testing block size  = $bs"
        time sudo dd if=/var/tmp/infile of=$1 bs=$bs
done
rm /var/tmp/infile
