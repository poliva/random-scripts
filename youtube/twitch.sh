#!/bin/bash
# http://livestreamer.tanuki.se/en/latest/

URL=$1
if [ -z "$URL" ]; then
	URL="http://www.twitch.tv/arkadeum"
fi

#QUALITY="high"
QUALITY="best,high"
#QUALITY="best,source,high,low,medium,mobile,worst"

#PLAYER="mplayer -cache-min 60 -cache 8192" 
#PLAYER="mplayer"
PLAYER="totem"

#livestreamer "${URL}" ${QUALITY} -v --player-fifo --player-continuous-http --player "${PLAYER}"
livestreamer "${URL}" ${QUALITY} -v --player-continuous-http --player "${PLAYER}"
