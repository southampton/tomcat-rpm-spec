#!/bin/bash

# The mirror of Tomcat to download from
MIRRORBASE="http://mirrors.ukfast.co.uk/sites/ftp.apache.org/tomcat"

# The major and minor versions of the version of Tomcat to download
TOMCAT_MAJOR_VERSION=8
TOMCAT_MINOR_VERSION=5

###############################################################################

# Check configuration parameters
if [ "x$MIRRORBASE" == "x" ]; then
	echo "MIRRORBASE not set - edit script configuration before running"
	exit 1;
fi
if [ "x$TOMCAT_MAJOR_VERSION" == "x" ]; then
	echo "TOMCAT_MAJOR_VERSION not set - edit script configuration before running"
	exit 1;
fi
if [ "x$TOMCAT_MINOR_VERSION" == "x" ]; then
	echo "TOMCAT_MINOR_VERSION not set - edit script configuration before running"
	exit 1;
fi

# Download directory listing
wget --quiet -O /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html "${MIRRORBASE}/tomcat-${TOMCAT_MAJOR_VERSION}" > /dev/null
if [ "x$?" != "x0" ]; then
	echo "Tomcat version check download failed"
	exit 1;
fi

# Get a list of version numbers that are available
cat /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html | fgrep '[DIR]' | grep -E "v${TOMCAT_MAJOR_VERSION}.${TOMCAT_MINOR_VERSION}.[0-9]+/" | grep -Eo '<a[ \t]+href[ \t]*=[ \t]*"[^"]*"' | grep -Eo "v${TOMCAT_MAJOR_VERSION}\.${TOMCAT_MINOR_VERSION}\.[^\"]*" | sed 's|/$||' > /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt

# Sort the release numbers to get the latest release
TOMCAT_RELEASE=`cat /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt | cut -d. -f3 | sort -nr | head -n1`
TOMCAT_VERSION=${TOMCAT_MAJOR_VERSION}.${TOMCAT_MINOR_VERSION}.${TOMCAT_RELEASE}
TOMCAT_URL=${MIRRORBASE}/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Tidy up
#rm -f /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html
#rm -f /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt

# Figure out where to download to based on the location of this script
OUR_PATH=$(dirname $(readlink -f $0))
DOWNLOAD_PATH=${OUR_PATH}/SOURCES/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Debug output
echo "Detected latest version: $TOMCAT_VERSION"
echo "Using URL: ${TOMCAT_URL}"
echo "Saving to: ${DOWNLOAD_PATH}"
echo
echo "Downloading..."

# Download Tomcat
wget --quiet -O ${DOWNLOAD_PATH} $TOMCAT_URL
if [ "x$?" != "x0" ]; then
	echo "Failed to download Tomcat"
	exit 1;
fi

echo "Download succeeded. You should verify that the correct package has been downloaded."

echo -n "Update the RPM spec file to the latest version [y/n]? "
read UPDATE

if [ "x$UPDATE" == "xy" ] || [ "x$UPDATE" == "xY" ]; then
	SPEC_PATH=${OUR_PATH}/SPECS/uostomcat.spec

	sed -ri "s/^(%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${TOMCAT_VERSION}/" ${SPEC_PATH}
	if [ "x$?" == "x0" ]; then
		echo "RPM spec file updated"
	else
		exit 1
	fi

	echo -n "Build updated RPMs [y/n]? "
	read BUILD

	if [ "x$BUILD" == "xy" ] || [ "x$BUILD" == "xY" ]; then
		$OUR_PATH/build.sh
	fi
fi
