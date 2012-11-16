#!/bin/bash

# script to build a debian package from a github tag, and upload it to launchpad
# (c) 2011-2012 Pau Oliva Fora - pof[at]eslack(.)org

#https://wiki.ubuntu.com/PackagingGuide/Basic#Building%20the%20Source%20Package
#https://help.launchpad.net/Packaging/PPA/BuildingASourcePackage
#https://help.launchpad.net/Packaging/PPA/Uploading

PROGRAM="$1"
VERSION="$2"
PPANAME="$3"

FOLDER="debianize-${PROGRAM}"
PPA="ppa:poliva/$PPANAME"
#PPA="ppa:poliva/lightum-mba"
#PPA="ppa:poliva/pof"

if [ -z $PPANAME ]; then
	echo "Usage: $0 <program> <version> <ppa-name>"
	echo "examples: "
	echo "       $0 lightum 1.6 lightum-mba"
	echo "       $0 indicator-sysbat 1.0 pof"
	echo ""
	echo "will fetch tarball from https://github.com/poliva/{program}/tarball/v{version}"
	exit 1
fi

if [ ! -e ${FOLDER} ]; then
	echo "'${FOLDER}' doesnt exist!!"
	exit 1
fi

echo "Ready to upload ${PROGRAM}-${VERSION} to ubuntu ppa repo ${PPA}"
echo "Make sure you have tagged version ${VERSION} on github"
echo "Press any key to continue, or Ctrl+C to cancel now."
read pause

export DEBFULLNAME="Pau Oliva Fora (pof)"
export DEBEMAIL="pau@eslack.org"

cd ${FOLDER}
wget https://github.com/poliva/${PROGRAM}/tarball/v${VERSION}
mv v${VERSION} v${VERSION}.tar.gz
tar zxvfp v${VERSION}.tar.gz
mv poliva-${PROGRAM}-* ${PROGRAM}-${VERSION}

if [ ! -e ${PROGRAM}-${VERSION} ]; then
	echo "'${FOLDER}/${PROGRAM}-${VERSION}' doesnt exist!!"
	exit 1
fi

tar cvfz ${PROGRAM}-${VERSION}.tar.gz ${PROGRAM}-${VERSION}
cp ${PROGRAM}-${VERSION}.tar.gz ${PROGRAM}_${VERSION}.orig.tar.gz
cd ${PROGRAM}-${VERSION}
read -n 1 -r -p 'Press any key to update the changelog, remember to change the VERSION number in the first line!!. ' choice
#rm debian/changelog
#dch --create
dch -i
debuild -S
UBU=`head -n1 debian/changelog |awk '{print $2}' |sed -e "s/(//g" -e "s/)//g"`
# keep the local changelog file synced
cp debian/changelog ~/Development/${PROGRAM}/debian/changelog
cd ..
lintian -Ivi ${PROGRAM}_${UBU}.dsc
echo
read -n 1 -r -p 'To upload your source package to ppa, press Y. To quit, press any other key. ' choice
echo
case "$choice" in
	[Yy]) ;;
	*) exit 1;;
esac
SOURCECHANGES=`ls -art ${PROGRAM}_${VERSION}*_source.changes |tail -n 1`
dput ${PPA} ${SOURCECHANGES}
