#!/bin/bash
# tv3 a la carta donwloader
# (c) 2012 pau oliva fora

if [ -z $1 ]; then
	echo "Usage: $0 video-id"
	echo "	Example: http://www.tv3.cat/3alacarta/videos/3975330"
	echo "		the video-id is: 3975330"
	exit 1
fi

video=$1
OUT=$(curl -m 10 -s "http://www.tv3.cat/su/tvc/tvcConditionalAccess.jsp?ID=${video}&QUALITY=H&FORMAT=MP4")
RTMP=$(echo ${OUT} |sed -e "s/ /\n/g" |grep rtmp |cut -f 2 -d ">" |cut -f 1 -d "<" |grep "^rtmp")
rtmpdump -r "${RTMP}" -o "${video}.mp4"
# si falla afegir --resume al rtmpdump :P
