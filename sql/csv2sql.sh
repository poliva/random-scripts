#!/bin/bash

cat $1 |sed -e "s/'/\\\'/g" |sed -e "s/^/'/" |sed -e "s/;/','/g" |sed -e "s/$/'/" |sed 's/;;/;;/;s/\(^.*$\)/REPLACE INTO TABLE VALUES\(\1\);/' |mysql -u root -p"PASSWORD" DATABASE
