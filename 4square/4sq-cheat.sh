#!/bin/bash
# forsquare automatic checkin
# (c)2010 Pau Oliva

EMAIL="your@email.com"
PASS="your_password"

if [ -z $1 ]; then echo "Usage: $0 <venue id>" ; exit 1 ; fi

# see: (http://foursquare.com/venue/4218564)
venue=$1

TEMP=`mktemp`
curl -s -A "Mozilla" "http://foursquare.com/venue/$venue" -o $TEMP
geolat=`cat $TEMP |grep "og:latitude" |cut -f 2 -d "\""`
geolong=`cat $TEMP |grep "og:longitude" |cut -f 2 -d "\""`
rm $TEMP

echo "geolocation: $geolat, $geolong"

# randomize the lat/lon a bit so we don't use always the same exact location

# get two 3 digit random numbers
rndlat=`echo ${RANDOM}${RANDOM}${RANDOM} |cut -c 1-3`
rndlon=`echo ${RANDOM}${RANDOM}${RANDOM} |cut -c 1-3`

# cut the last 3 digit from the actual lat/long
shortlat=`echo $geolat |rev |cut -c 4- |rev`
shortlon=`echo $geolong |rev |cut -c 4- |rev`

# generate the randomized lat/lon
geolat=${shortlat}${rndlat}
geolong=${shortlon}${rndlon}

echo "randomized location: $geolat, $geolong"

UA="pof-checkin:1.0"
curl -A "$UA" -u "$EMAIL:$PASS" -d "vid=$venue&geolat=$geolat&geolong=$geolong" "http://api.foursquare.com/v1/checkin" -o $TEMP
tidy -xml $TEMP 2>/dev/null
rm $TEMP
