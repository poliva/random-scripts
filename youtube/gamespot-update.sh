#!/bin/bash
# script to periodically update the GameSpot Verus CSV database
# (c) 2014 Pau Oliva (@pof)

DBFILE=/home/pau/bin/gamespot.csv
last=`tail -n 1 $DBFILE |cut -f 1 -d ";"`
TMPDIR="/tmp/temp.$$.$RANDOM"

mkdir -p ${TMPDIR} && cd ${TMPDIR}

youtube-dl --dateafter ${last} --skip-download --write-info-json --write-description --output '%(id)s.%(ext)s' --restrict-filenames https://www.youtube.com/user/supersf2turbo/videos &

sleep 1m && pkill youtube-dl

for f in `ls -at -- *.description` ; do gamespot-filter.sh "$f" ; done |grep -v "^${last};" |tee -a ${DBFILE}

rm -rf ${TMPDIR}
