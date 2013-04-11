#!/bin/bash
if [ ! -e "$1" ]; then 
	echo "Usage: `basename $0` <classes.dex>"
	exit 1
fi
radare2 -nwq -c 'wx `#sha1 $s-32 @32` @12 ; wx `#adler32 $s-12 @12` @8' $1
