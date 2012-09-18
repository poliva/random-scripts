#!/bin/bash
# get geolocation exif data from picture and generate a google maps link
# (c) 2011 Pau Oliva - Licensed under GPLv3

if [ ! -f $1 ]; then echo "Usage: $0 <image>"; exit 1 ; fi
which exif >/dev/null
if [ $? != 0 ]; then echo "Please install exif package" ; exit 1 ; fi
which bc >/dev/null
if [ $? != 0 ]; then echo "Please install bc package" ; exit 1 ; fi

TMP=`tempfile`
exif -x $1 > $TMP

# convert from deg/min/sec to decimal for Google  
strLatRef=`cat $TMP |grep "<North_or_South_Latitude>" |cut -f 2 -d ">" |cut -f 1 -d "<"`
strLongRef=`cat $TMP |grep "<East_or_West_Longitude>" |cut -f 2 -d ">" |cut -f 1 -d "<"`
aLat0=`cat $TMP |grep "<Latitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 1 -d "," |sed -e "s/ //g"`
aLat1=`cat $TMP |grep "<Latitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 2 -d "," |sed -e "s/ //g"`
aLat2=`cat $TMP |grep "<Latitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 3 -d "," |sed -e "s/ //g"`
aLong0=`cat $TMP |grep "<Longitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 1 -d "," |sed -e "s/ //g"`
aLong1=`cat $TMP |grep "<Longitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 2 -d "," |sed -e "s/ //g"`
aLong2=`cat $TMP |grep "<Longitude>" |cut -f 2 -d ">" |cut -f 1 -d "<" |cut -f 3 -d "," |sed -e "s/ //g"`
rm $TMP

if [ -z $strLatRef ] || [ -z $strLongRef ] || [ -z $aLat0 ] || [ -z $aLong0 ]; then
	echo "Not enough exif data on this picture"
	exit 1
fi

fLat=`echo "$aLat0 + ($aLat1/60) + ($aLat2/3600)" |bc -l`
if [ "$strLatRef" == "S" ]; then
	fLat=`echo "$fLat * -1" |bc -l`
fi
fLat=`echo $fLat |cut -c 1-10`

fLong=`echo "$aLong0 + ($aLong1/60) + ($aLong2/3600)" |bc -l`
if [ "$strLongRef" == "W" ]; then
	fLong=`echo "$fLong * -1" |bc -l`
fi
fLong=`echo $fLong |cut -c 1-10`

echo "http://maps.google.com/maps?q=$fLat,$fLong"
