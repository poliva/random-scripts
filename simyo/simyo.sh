#!/bin/bash
#
# quick-n-dirty simyo.es consumption checker v2
# (c) 2013 Pau Oliva - pof [at] eslack (.) org
#
# license: WTFPL (Do What The Fuck You Want To Public License)
# 
# api functions reverse engineered from the com.simyo android app

# enter your simyo.es username and password here:

USERNAME=""
PASSWORD=""

if [ -z "$USERNAME" ]; then
	echo "Edit the script to enter your username/password"
	exit 1
fi

VERBOSE=0
VAL=""
for opt in $* ; do
	case $opt in
		"-v") VERBOSE=1  ;;
		"-b")
			VAL="billCycle"
			continue
		;;
		"-h")
			echo "Usage: $0 [-h|-v|-b num]"
			echo "    -h     : show this help"
			echo "    -v     : verbose mode"
			echo "    -b num : bill cycle (from 1 to 6)"
			exit 0
		;;
	esac
	case $VAL in
		"billCycle")
			billCycle=$opt
			VAL=""
		;;
		*) VAL=""
	esac
done

if [ -z "$billCycle" ]; then
	billCycle=1
fi
if [ "$billCycle" -gt 6 ]; then
	echo "Billing Cylce must be an integer from 1 (current month) to 6"
	exit 1
fi

SIMYOPASS=$(php tripledes.php $PASSWORD 2>/dev/null)
kPublicKey="a654fb77dc654a17f65f979ba8794c34"

function getApiSig() {
	LOL=$(echo ${1} |tr [:upper:] [:lower:])
	LOL="f25a2s1m10${LOL}"
	php -r "error_reporting(0);\$s=hash_hmac('sha256', \"${LOL}\", 'f25a2s1m10', true); echo \$s;" |xxd -ps -c 100
}

function getJsonValue() {
	key="$1"
	file="$2"
	local J=$(cat $file)
	python -c "import json;print json.loads('$J')${key}"
}

#### login
function api_login() {
	URL="https://www.simyo.es/api/login?publicKey=${kPublicKey}"
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s -d "user=${USERNAME}&password=${SIMYOPASS}&apiSig=null" "${URL}" -o auth.json
	if [ $VERBOSE -eq 1 ]; then json_pp < auth.json ; fi

	sessionId=$(getJsonValue "['response']['sessionId']" auth.json)
	customerId=$(getJsonValue "['response']['customerId']" auth.json)

	if [ -z "$customerId" ]; then
		echo "Something went wrong."
		exit 1
	fi
}

#### subscriptions
function subscriptions() {
	URL="https://www.simyo.es/api/subscriptions/${customerId}?sessionId=${sessionId}&publicKey=${kPublicKey}" 
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s "$URL" -o subscriptions.json
	if [ $VERBOSE -eq 1 ]; then json_pp < subscriptions.json ; fi

	registerDate=$(getJsonValue "['response']['subcriptions'][0]['registerDate']" subscriptions.json)
	mainProductId=$(getJsonValue "['response']['subcriptions'][0]['mainProductId']" subscriptions.json)
	billCycleType=$(getJsonValue "['response']['subcriptions'][0]['billCycleType']" subscriptions.json)
	msisdn=$(getJsonValue "['response']['subcriptions'][0]['msisdn']" subscriptions.json)
	subscriberId=$(getJsonValue "['response']['subcriptions'][0]['subscriberId']" subscriptions.json)
	payType=$(getJsonValue "['response']['subcriptions'][0]['payType']" subscriptions.json)
}

#### consumptionByCycle
function consumptionByCycle() {
	URL="https://www.simyo.es/api/consumptionByCycle/${customerId}?sessionId=${sessionId}&msisdn=${msisdn}&billCycleType=${billCycleType}&registerDate=${registerDate}&billCycle=${billCycle}&billCycleCount=${billCycleCount}&payType=${payType}&publicKey=${kPublicKey}"
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s "$URL" -o consumptionByCicle.json
	if [ $VERBOSE -eq 1 ]; then json_pp < consumptionByCicle.json ; fi
}

#### consumptionDetailDetailByCycle
function consumptionDetailDetailByCycle() {
	URL="https://www.simyo.es/api/consumptionDetailByCycle/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&billCycle=${billCycle}&registerDate=${registerDate}&billCycleCount=${billCycleCount}&payType=${payType}&publicKey=${kPublicKey}"
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s "$URL" -o consumptionDetailByCicle.json
	if [ $VERBOSE -eq 1 ]; then json_pp < consumptionDetailByCicle.json ; fi
}


#### invoiceList
function invoiceList() {
	URL="https://www.simyo.es/api/invoiceList/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&registerDate=${registerDate}&publicKey=${kPublicKey}"
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s "$URL" -o invoiceList.json
	if [ $VERBOSE -eq 1 ]; then json_pp < invoiceList.json ; fi
}

### TODO
#https://www.simyo.es/api/invoiceList/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&registerDate=${registerDate}&publicKey=${kPublicKey}
#https://www.simyo.es/api/downloadInvoice?sessionId=${sessionId}&invoiceNO=${invoiceNO}&invoiceId=${invoiceId}&publicKey=${kPublicKey}
#https://www.simyo.es/api/contact?publicKey=${kPublicKey}

#https://www.simyo.es/api/frequentNumbers/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&registerDate=${registerDate}&month=${month}&publicKey=${kPublicKey}
#https://www.simyo.es/api/messages/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&billCycle=${billCycle}&registerDate=${registerDate}&start=${start}&count=${count}&publicKey=${kPublicKey}
#https://www.simyo.es/api/mgmHistory/${customerId}?sessionId=${sessionId}&publicKey=${kPublicKey}
#https://www.simyo.es/api/rechargeHistory/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&registerDate=${registerDate}&startDate=${startDate}&endDate=${endDate}&publicKey=${kPublicKey}
#https://www.simyo.es/api/voiceCalls/${customerId}?msisdn=${msisdn}&sessionId=${sessionId}&billCycleType=${billCycleType}&billCycle=${billCycle}&registerDate=${registerDate}&start=${start}&count=${count}&publicKey=${kPublicKey}

#### logout
function api_logout() {
	URL="https://www.simyo.es/api/logout?sessionId=${sessionId}&publicKey=${kPublicKey}"
	apiSig=$(getApiSig $URL)
	URL="${URL}&apiSig=${apiSig}"
	curl -s "$URL" -o logout.json
	if [ $VERBOSE -eq 1 ]; then json_pp < logout.json ; fi
}


api_login
subscriptions
consumptionByCycle
#consumptionDetailDetailByCycle
#invoiceList
api_logout

J=$(cat consumptionByCicle.json)

startDate=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['startDate']" |cut -c 1-10)
endDate=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['endDate']" |cut -c 1-10)

start=$(date -d@${startDate} "+%d/%m/%y")
end=$(date -d@${endDate} "+%d/%m/%y")
echo
echo "Periodo de $start a $end"
echo

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voice']['count']")
chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voice']['chargeTotal']")
hms=$(echo "obase=60;${count}" | bc |sed -e "s/^ //" -e "s/$/ /g" |rev |sed -e "s/ /s/" -e "s/ /m/" -e "s/ /h/" -e "s/ /d/" |rev |sed -e "s/d/d /" -e "s/h/h /" -e "s/m/m /")
echo "Llamadas: ${hms} (${chargeTotal} EUR)"

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['sms']['count']")
chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['sms']['chargeTotal']")
echo "SMS: ${count} (${chargeTotal} EUR)"

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['mms']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['mms']['chargeTotal']")
	echo "MMS: ${count} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['data']['count']")
chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['data']['chargeTotal']")
count=$(echo "scale=2; $count/1024/1024" |bc) # bytes to megabytes
echo "Datos: ${count} MB (${chargeTotal} EUR)"

PRINT=0

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voicePremium']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voicePremium']['chargeTotal']")
	hms=$(echo "obase=60;${count}" | bc |sed -e "s/^ //" -e "s/$/ /g" |rev |sed -e "s/ /s/" -e "s/ /m/" -e "s/ /h/" -e "s/ /d/" |rev |sed -e "s/d/d /" -e "s/h/h /" -e "s/m/m /")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "Llamadas Premium: ${hms} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['smsPremium']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['smsPremium']['chargeTotal']")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "SMS Premium: ${count} (${chargeTotal} EUR)"
fi

PRINT=0

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voiceOutgoingRoaming']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voiceOutgoingRoaming']['chargeTotal']")
	hms=$(echo "obase=60;${count}" | bc |sed -e "s/^ //" -e "s/$/ /g" |rev |sed -e "s/ /s/" -e "s/ /m/" -e "s/ /h/" -e "s/ /d/" |rev |sed -e "s/d/d /" -e "s/h/h /" -e "s/m/m /")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "Llamadas Salientes Roaming: ${hms} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voiceIngoingRoaming']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['voiceIngoingRoaming']['chargeTotal']")
	hms=$(echo "obase=60;${count}" | bc |sed -e "s/^ //" -e "s/$/ /g" |rev |sed -e "s/ /s/" -e "s/ /m/" -e "s/ /h/" -e "s/ /d/" |rev |sed -e "s/d/d /" -e "s/h/h /" -e "s/m/m /")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "Llamadas Entrantes Roaming: ${hms} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['smsRoaming']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['smsRoaming']['chargeTotal']")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "SMS Roaming: ${count} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['mmsRoaming']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['mmsRoaming']['chargeTotal']")
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "MMS Roaming: ${count} (${chargeTotal} EUR)"
fi

count=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['dataRoaming']['count']")
if [ $count -gt 0 ]; then
	chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['dataRoaming']['chargeTotal']")
	count=$(echo "scale=2; $count/1024/1024" |bc) # bytes to megabytes
	if [ $PRINT -eq 0 ]; then echo ; PRINT=1 ; fi
	echo "Datos Roaming: ${count} MB (${chargeTotal} EUR)"
fi

echo

chargeTotal=$(python -c "import json;print json.loads('$J')['response']['consumptionsByCycle'][0]['chargeTotal']")
echo "Consumo total: ${chargeTotal} EUR"
echo
