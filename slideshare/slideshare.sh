#!/bin/bash
# quick-n-dirty slideshare search by command line :)
# (c) 2012 pau oliva fora

if [ -z $1 ]; then
	echo "Usage: $0 [search query]"
	exit 1
fi

echo "Searching slideshare for: $*"

query=`echo $* | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g'`

curl -s "http://www.slideshare.net/search/slideshow.json?q=$query&type=presentations&sort=latest&ud=any&ft=all&ru=undefined&qf=default" -o - |sed -e "s:{:\n{:g" |cut -f 13,16 -d ":" |sed -e 's:"::g' -e "s/,id:/\//g" -e "s/,description//g" -e "s:^:http\://www.slideshare.net/:g" |grep -v "^http://www.slideshare.net/$" |grep -v "time_ago" |grep -v "category_id"
