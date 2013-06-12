#!/usr/bin/env bash
echo '*** Starting Barbican build phase ***'
pwd

BUILD_ADDR=<put-build-box-endpoint-or-IP-here>
BUILD_FOLDER=/root/builddir
TARGET_ADDR=<put-target-node-endpoint-or-IP-here>:<target-node-port>

# Pull latest code in
#   TBD: Revisit this...shouldn't need to do this...
git checkout master
git pull
rm -rf dist

# Create the release version and git tag.
#   TBD: Move away from this, need to spin up on OpenStack and Reach approaches more here.
bin/versionrelease
export PROJECT_RELEASE_VER="$(cat versiononly.txt)"
git add barbican/version.py
git add debian/changelog
git commit -m 'Release for v'$PROJECT_RELEASE_VER
git tag -a $PROJECT_RELEASE_VER -m 'Project Barbican Release: '$PROJECT_RELEASE_VER
git push origin master
git push origin $PROJECT_RELEASE_VER

# Make a release tar ball.
TAR=barbican_$PROJECT_RELEASE_VER.orig.tar.gz
pushd ..
rm $TAR
cp -rf py27 barbican-$PROJECT_RELEASE_VER
tar -cvzf $TAR barbican-$PROJECT_RELEASE_VER --exclude=barbican-$PROJECT_RELEASE_VER/.git* --exclude=barbican-$PROJECT_RELEASE_VER/.tox --exclude=barbican-$PROJECT_RELEASE_VER/build
rm -rf barbican-$PROJECT_RELEASE_VER
popd

# Sleep for a bit, to see if this is causing the git issue of the push below failing.
sleep 60

# Bump to the next dev version
bin/versionbump
git add barbican/version.py
git add debian/changelog
git commit -m 'Prepare for next release'
git push origin master
cat barbican/version.py

# Push out to our build box and repository.
scp ../barbican_$PROJECT_RELEASE_VER.orig.tar.gz root@$BUILD_ADDR:$BUILD_FOLDER

# Build and install into remote archive
set -x
knife ssh -a ipaddress -x root -P <put-build-box-pw-here> 'role:web-node-deb' 'cd /root/builddir && ./addtorepo.sh '$(echo $TAR)

# Check that the correct version has propagated.
VERSION_FOUND=""
for i in {1..20}
do
  echo Starting deploy verify loop $i...
  sleep 20

  # Let the remote node update to the latest code.
  knife ssh -a ipaddress -x root -P <put-target-test-node-pw-here> 'role:web-node-deb' 'apt-get update -y --force-yes && apt-get install barbican -y --force-yes'
  sleep 10  

  # Check if the app is stood up on the remote node, with the correct version.
  curl $TARGET_ADDR | grep $PROJECT_RELEASE_VER  1>/dev/null 
  if [ `echo $?` -eq 0 ]
  then
  VERSION_FOUND=$PROJECT_RELEASE_VER
  echo Version $PROJECT_RELEASE_VER detected on $TARGET_ADDR
  break
  else 
  echo $PROJECT_RELEASE_VER not yet detected on $TARGET_ADDR...waiting more time...
  fi

  sleep 1m
done

echo $VERSION_FOUND | grep $PROJECT_RELEASE_VER 1>/dev/null
if [ `echo $?` -eq 0 ]
then
echo Version $PROJECT_RELEASE_VER detected on $TARGET_ADDR
else 
echo Version $PROJECT_RELEASE_VER was NOT DETECTED on $TARGET_ADDR, failing job...
exit -1
fi

exit 0
