#!/bin/bash
#
# GameSpot Versus CSV Generator - (c) 2014 Pau Oliva (@pof)
#
# first download the metadata from all the videos (since December 2012):
# /home/pau/bin/youtube-dl --dateafter 20121201 --skip-download --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos
#
# then run like this:
# for f in `ls -at -- *.description` ; do gamespot-filter.sh "$f" ; done |tee -a /tmp/gamespot.csv
#

file=$1
if [ ! -e "$1" ]; then
	echo "USAGE: $0 <file>"
	exit 1
fi
id=$(echo $file |cut -f 1 -d ".")
out=`tempfile`
date=$(cat -- $id.info.json |json_pp |grep upload_date |cut -f 2 -d ":" |cut -f 2 -d '"')
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
