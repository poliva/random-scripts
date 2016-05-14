#!/bin/bash
# Script to search the GameSpot Verus database
# (c) 2014-2016 Pau Oliva (@pof)

DBFILE=~/bin/gamespot.csv
sleep_sec=0

function create_dbfile() {
	TMPDIR="/tmp/temp.$$.$RANDOM"
	mkdir -p ${TMPDIR} && cd ${TMPDIR}

	if [ $sleep_sec != 0 ]; then
		echo "youtube-dl --dateafter ${last} --skip-download --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos"
		youtube-dl --dateafter ${last} --skip-download --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos &
		sleep ${sleep_sec} && ( ps ax |grep youtube-dl |grep -v grep |awk '{print $1}' |xargs -n 1 kill )
	else
		youtube-dl --dateafter ${last} --skip-download --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos
	fi

	for f in `ls -at -- *.description` ; do gamespot_filter "$f" ; done |grep -v "^${last};" |tee -a ${DBFILE}

	rm -rf ${TMPDIR}
}

function gamespot_filter() {
	file=$1
	if [ ! -e "$file" ]; then
		echo "ERROR: $file does not exist"
		exit 1
	fi
	id=$(echo $file |cut -f 1 -d ".")
	out="/tmp/temp.$$.$RANDOM"
	date=$(cat -- $id.info.json |jq -M . |grep upload_date |cut -f 2 -d ":" |cut -f 2 -d '"')
	if [ -z "$date" ]; then
		# date: %m%d%Y
		date=$(cat -- $file |head -n 1 |grep -o [0-9][0-9][0-9][0-9][0-9][0-9])
		if [ -z $date ]; then
			date=999999
		fi
		month=`echo $date |cut -c 1,2`
		day=`echo $date |cut -c 3,4`
		year=`echo $date |cut -c 5,6`
		if [ "$month" -gt 12 ]; then
			day=`echo $date |cut -c 1,2`
			month=`echo $date |cut -c 3,4`
		fi
		date="20${year}${month}${day}"
	fi
	cat -- $file |grep "^[0-9][0-9]:[0-9][0-9] " |sed -e "s/ vs\. //" -e "s/ vs //" > $out
	len=`cat $out |wc -l`
	for f in `seq 1 $len` ; do
		LINE=`cat $out |head -n $f |tail -n 1`
		time=`echo $LINE |awk '{print $1}' |sed -e "s/:/m/" -e "s/$/s/"`
		name1=`echo $LINE |cut -f 2- -d " " |cut -f 1 -d "(" |sed -e "s/ $//"`
		char1=`echo $LINE |cut -f 2 -d "(" |cut -f 1 -d ")" |sed -e "s/ $//"`
		name2=`echo $LINE |cut -f 2- -d ")" |cut -f 1 -d "(" |sed -e "s/ $//"`
		char2=`echo $LINE |cut -f 3 -d "(" |cut -f 1 -d ")" |sed -e "s/ $//"`
		echo "$date;http://youtu.be/${id}?t=$time;$char1;$char2;$name1;$name2;"
	done
	rm $out
}


if [ -f $DBFILE ]; then
	last=`tail -n 1 $DBFILE |cut -f 1 -d ";"`
	sleep_sec=60
else
	mkdir -p ~/bin/
	last=20121201
	echo "Database not found, creating database for the first time. Please wait..."
	create_dbfile
fi

if [ -z "$last" ]; then
	last=20121201
fi

term1=$1
term2=$2
if [ -z "$term1" ]; then
	echo "USAGE: $0 <term1> [<term2>]"
	exit 1
fi

today=$(date '+%Y%m%d')
diff=$(( $today - $last ))
if [ $diff -gt 100 ]; then
	echo "Database is too old, adding new entries. Please wait..."
	create_dbfile
fi

if [ -z "$term2" ]; then
	cat $DBFILE |column -s ';' -t |grep -A1 --color -i "$term1"
else
	cat $DBFILE |grep -A1 -i "$term1" |grep -i -A1 "$term2" |egrep -i "(^--|$term1.*$term2|$term2.*$term1)" |column -s ';' -t |egrep -A1 --color -i "($term1|$term2)"
fi
