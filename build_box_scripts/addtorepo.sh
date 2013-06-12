#!/bin/bash
## $1 is the tarball to insert into the repository with form <package>_<version>.orig.tar.gz
echo 'Packaging tar ball: ' $1

## Assign basic configuration
GPG_KEY_ID=<put-gpg-key-here>
USER=debian
TARGET=/var/ftp/debian
RAW_PKG=$(echo ${1%.orig.tar.gz})
echo '...raw directory: ' $RAW_PKG
#FULL_PKG=$(echo ${RAW_PKG/*./-})
FULL_PKG=$(echo ${RAW_PKG/_/-})
echo '...,,,building in directory: ' $FULL_PKG
TARGET=/var/ftp/debian
TARGET_POOL=$TARGET/pool/main

##TBD: Use lock file to sync things?

## Setup to use GPG keys
#TBD: GPGDIR=/home/${USER}/.gnupg
#TBD: GPGKEY=<insert id of the subkey here just to be specific>

## Build and copy over the debian package
echo '...building in directory: ' $FULL_PKG
mkdir -p $FULL_PKG
pushd $FULL_PKG
rm *.deb
rm *.gz
mv ../$1 $1
touch $1
tar -xvzf $1
cd $FULL_PKG
echo '...making deb package(s)'
debuild -us -uc
cd ..
cp *.deb $TARGET_POOL
popd

## Do the actual work
##    This is based on the setup here: http://www.debian.org/doc/manuals/debian-reference/ch02.en.html (Section 2.7.15)
pushd /var/ftp/debian
apt-ftparchive generate -c=aptftp.conf aptgenerate.conf
apt-ftparchive release -c=aptftp.conf dists/stable >dists/stable/Release
rm -f dists/unstable/Release.gpg
gpg --yes -u $GPG_KEY_ID -bao dists/stable/Release.gpg dists/stable/Release
cd ..
chown -R ftp:ftp debian/
popd
#TBD: rm -f ${TARGET}/Release.gpg
#TBD: rsync -a ${SOURCE}/*.deb ${TARGET}/
##   Note: Based on http://nytefyre.net/2013/03/creating-signed-debian-apt-repository/
#olddpkg-scanpackages --multiversion ${TARGET} /dev/null > ${TARGET}/Packages
#oldgzip -9c ${TARGET}/Packages > ${TARGET}/Packages.gz
#oldapt-ftparchive -c=${TARGET}/Releases.conf release ${TARGET} > ${TARGET}/Release
#TBD: gpg -a --homedir ${GPGDIR} --default-key ${GPGKEY} -o ${TARGET}/Release.gpg ${TARGET}/Release

