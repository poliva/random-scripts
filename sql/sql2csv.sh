#!/bin/bash
QUERY="$1"
mysql -u root -p"PASSSWORD" -e "$QUERY" TABLE |sed -e "s/\t/;/g"
