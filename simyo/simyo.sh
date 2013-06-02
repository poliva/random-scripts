#!/bin/bash
#
# quick-n-dirty simyo.es consumption checker
# (c) 2012 Pau Oliva - pof [at] eslack (.) org
#
# license: WTFPL (Do What The Fuck You Want To Public License)
# 
# depends: bash, curl, lynx, tidy, sed, grep, egrep, cut, rev, ...

# enter your simyo.es username and password here:
USERNAME=""
PASSWORD=""

if [ -z "$USERNAME" ]; then
	echo "Edit the script to enter your username/password"
	exit 1
fi

UA="Firefox"
CURL="curl -A $UA -s -m 45"
COOKIE="/tmp/cookie.txt"

DEBUG=0
TEST=0
VAL=""
for opt in $* ; do
	case $opt in
		"-t") TEST=1  ;;
		"-b")
			VAL="BC"
			continue
		;;
		"-h")
			echo "Usage: $0 [-h|-t|-b num]"
			echo "    -h     : show this help"
			echo "    -t     : test mode (for development)"
			echo "    -b num : bill cycle (from 1 to 6)"
			exit 0
		;;
	esac
	case $VAL in
		"BC")
			BC=$opt
			VAL=""
		;;
		*) VAL=""
	esac
done

if [ -z "$BC" ]; then
	BC=1
fi
if [ "$BC" -gt 6 ]; then
	echo "Billing Cylce must be an integer from 1 (current month) to 6"
	exit 1
fi

if [ "$TEST" -eq 1 ]; then
	RES=$(cat samples/detail.html |tidy -w 200 2>/dev/null |egrep -A2 '(VOICE|SMS|MMS|DATA|consumidos).*span' |lynx -dump --stdin |sed -e "s/--//g")
	RES2=$(cat samples/panel.html |tidy -w 200 2>/dev/null)
else
	count=0
	echo -n "Connecting to simyo..."
	while [ -z "$RES" ]; do
		count=$(($count + 1))
		echo -n "."
		$CURL -c $COOKIE https://www.simyo.es/simyo/publicarea/login/j_security_check -o /dev/null
		echo -n "."
		$CURL -L -b $COOKIE -d "j_username=$USERNAME&j_password=$PASSWORD&x=108&y=21" https://www.simyo.es/simyo/publicarea/login/j_security_check -o /dev/null
		echo -n "."
		if [ "$DEBUG" -eq 1 ]; then
			mkdir samples 2>/dev/null
			$CURL -L -b $COOKIE https://www.simyo.es/simyo/privatearea/customer/consumption-panel.htm -o samples/panel.html
		else
			RES2=$($CURL -L -b $COOKIE https://www.simyo.es/simyo/privatearea/customer/consumption-panel.htm -o - |tidy -w 200 2>/dev/null)
		fi
		echo -n "."
		if [ "$DEBUG" -eq 1 ]; then
			$CURL -L -b $COOKIE -d "selectedBillCycle=${BC}" https://www.simyo.es/simyo/privatearea/customer/consumption-detail.htm -o samples/detail.html
		else
			RES=$($CURL -L -b $COOKIE -d "selectedBillCycle=${BC}" https://www.simyo.es/simyo/privatearea/customer/consumption-detail.htm -o - |tidy -w 200 2>/dev/null |egrep -A2 '(VOICE|SMS|MMS|DATA|consumidos).*span' |lynx -dump --stdin |sed -e "s/--//g")
		fi
		echo -n "."
		rm -f $COOKIE 
		echo -n "."
		if [ "$DEBUG" -eq 1 ]; then
			echo "Debug output saved in samples/*.html"
			exit 1
		fi
		if [ "$count" -ge 5 ]; then
			echo " FAIL!"
			exit 1
		fi
	done
	echo " OK!"
fi
echo

if [ -z "$RES2" ]; then BC=1 ; fi
MONTHS=$(( $BC - 1 ))
DATE=`date --date="$MONTHS month ago" "+%Y-%m"`
echo "Facturacion: $DATE"
echo

if [ "$BC" != 1 ] || [ -z "$RES2" ]; then
	RES=`echo $RES`
	echo "$RES" |sed -e "s/€ Total de MB consumidos: /EUR (/g" -e "s/€ /EUR\n/g" -e "s/MB /MB)\n/g" -e "s/MB$/MB)/g" -e "s/)/)\n/g"
	exit 0
fi

PANEL=$(echo "$RES2" |egrep -B3 -A3 '(Llamadas|SMS|MMS|Datos|Roaming)' |egrep "(^<td|td>$)")
DATA=`echo $PANEL |sed -e "s:</td> <td>:<br>:g" |lynx -dump --stdin |sed -e "s/   //g" -e "s/^ //g" -e "s: / :/:g" -e "s/€/EUR/g"`
if [ "$TEST" -eq 1 ]; then
	echo "===================="
	echo "$PANEL"
	echo "===================="
fi

#nacional
for f in Llamadas SMS MMS Datos ; do
        A=`echo "$DATA" |grep -i "$f" |egrep -vi "(EUR|roaming|premium)"`
        B=`echo "$DATA" |grep -i "$f" |egrep -vi "(roaming|premium)" |grep "EUR" |sed -e "s/ EUR/EUR/g" -e "s/EUR/ EUR/g" |rev |cut -f 1,2 -d " " |rev`
        echo "$A ($B)"
done
echo

#roaming
print=0
for f in Realizadas Recibidas SMS MMS Datos ; do
        A=`echo "$DATA" |grep -i "$f" |grep -v "EUR" |grep -i "roaming" |sed -e "s/roaming //gI"`
        B=`echo "$DATA" |grep -i "$f" |grep -i "roaming" |grep "EUR" |sed -e "s/ EUR/EUR/g" -e "s/EUR/ EUR/g" |rev |cut -f 1,2 -d " " |rev`
        if [ ! -z "$A" ] || [ ! -z "$B" ]; then
                if [ -z "$A" ]; then A="$f" ; fi
                if [ -z "$B" ]; then B="0 EUR" ; fi
                echo "Roaming $A ($B)"
		print=1
        fi
done
if [ "$print" -eq 1 ]; then echo ; fi

#premium
print=0
for f in Llamadas SMS ; do
        A=`echo "$DATA" |grep -i "$f" |grep -v "EUR" |grep -i "premium" |sed -e "s/premium //gI"`
        B=`echo "$DATA" |grep -i "$f" |grep -i "premium" |grep "EUR" |sed -e "s/ EUR/EUR/g" -e "s/EUR/ EUR/g" |rev |cut -f 1,2 -d " " |rev`
        if [ ! -z "$A" ] || [ ! -z "$B" ]; then
                if [ -z "$A" ]; then A="$f" ; fi
                if [ -z "$B" ]; then B="0 EUR" ; fi
		echo "$A ($B)" |sed -e "s/Llamadas/Llamadas Premium/g" -e "s/SMS /SMS Premium/g"
		print=1
        fi
done
if [ "$print" -eq 1 ]; then echo ; fi

echo "$RES2" |grep "Consumo total" |lynx -dump --stdin |sed -e "s/€/EUR/g" |grep -v "^$"
DIA=$(echo "$RES2" |grep "desde el d.*hasta hoy" |rev |cut -f 3 -d " " |rev)
echo "Periodo facturacion empieza el dia $DIA de cada mes"
