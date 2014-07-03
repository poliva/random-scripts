#!/bin/bash
#youtube-dl --skip-download --get-description --get-id --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos
term1=$1
term2=$2

DBFILE=/home/pau/bin/gamespot.csv

if [ -z "$term1" ]; then
	echo "USAGE: $0 <term1> [<term2>]"
	exit 1
fi

if [ -z "$term2" ]; then
	cat $DBFILE |column -s ';' -t |grep --color -i "$term1" 
else
	cat $DBFILE |grep -i "$term1" |grep -i "$term2" |column -s ';' -t |egrep --color -i "($term1|$term2)"
fi
