#!/bin/bash

if [ ! -e "$1" ]; then
	echo "Usage: $0 <file.apk>"
	exit 1
fi

unzip $1 META-INF/*.RSA -d /tmp/apkcert.$$/
openssl pkcs7 -inform DER -in /tmp/apkcert.$$/META-INF/*.RSA -noout -print_certs -text
#openssl pkcs7 -inform DER -in /tmp/META-INF/CERT.RSA -out CERT.pem -outform PEM -print_certs
keytool -printcert -file /tmp/apkcert.$$/META-INF/*.RSA
jarsigner -verify -certs -verbose $1
