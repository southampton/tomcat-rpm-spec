#!/bin/bash

# The mirror of Tomcat to download from
MIRRORBASE="http://mirrors.ukfast.co.uk/sites/ftp.apache.org/tomcat"

# The major and minor versions of the version of Tomcat to download
TOMCAT_MAJOR_VERSION=8
TOMCAT_MINOR_VERSION=5

###############################################################################

# Helper variables
COLOR_BOLD="\e[1m"
COLOR_SUCCESS="\e[1;92m"
COLOR_FAILURE="\e[1;91m"
COLOR_RESET="\e[0m"

# Check configuration parameters
if [ "x$MIRRORBASE" == "x" ]; then
	echo -e "${COLOR_FAILURE}MIRRORBASE not set - edit script configuration before running${COLOR_RESET}"
	exit 1;
fi
if [ "x$TOMCAT_MAJOR_VERSION" == "x" ]; then
	echo -e "${COLOR_FAILURE}TOMCAT_MAJOR_VERSION not set - edit script configuration before running${COLOR_RESET}"
	exit 1;
fi
if [ "x$TOMCAT_MINOR_VERSION" == "x" ]; then
	echo -e "${COLOR_FAILURE}TOMCAT_MINOR_VERSION not set - edit script configuration before running${COLOR_RESET}"
	exit 1;
fi

# Download directory listing
wget --quiet -O /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html "${MIRRORBASE}/tomcat-${TOMCAT_MAJOR_VERSION}" > /dev/null
if [ "x$?" != "x0" ]; then
	echo -e "${COLOR_FAILURE}Tomcat version check download failed${COLOR_RESET}"
	exit 1;
fi

# Get a list of version numbers that are available
cat /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html | fgrep '[DIR]' | grep -E "v${TOMCAT_MAJOR_VERSION}.${TOMCAT_MINOR_VERSION}.[0-9]+/" | grep -Eo '<a[ \t]+href[ \t]*=[ \t]*"[^"]*"' | grep -Eo "v${TOMCAT_MAJOR_VERSION}\.${TOMCAT_MINOR_VERSION}\.[^\"]*" | sed 's|/$||' > /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt

# Sort the release numbers to get the latest release
TOMCAT_RELEASE=`cat /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt | cut -d. -f3 | sort -nr | head -n1`
TOMCAT_VERSION=${TOMCAT_MAJOR_VERSION}.${TOMCAT_MINOR_VERSION}.${TOMCAT_RELEASE}
TOMCAT_URL=${MIRRORBASE}/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Tidy up
rm -f /tmp/tc${TOMCAT_MAJOR_VERSION}-index.html
rm -f /tmp/tc${TOMCAT_MAJOR_VERSION}-versions.txt

# Figure out where to download to based on the location of this script
OUR_PATH=$(dirname $(readlink -f $0))
DOWNLOAD_PATH=${OUR_PATH}/SOURCES/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Debug output
echo -e "Detected latest version: ${COLOR_SUCCESS}${TOMCAT_VERSION}${COLOR_RESET}"
echo -e "Using URL: ${COLOR_SUCCESS}${TOMCAT_URL}${COLOR_RESET}"
echo -e "Saving to: ${COLOR_SUCCESS}${DOWNLOAD_PATH}${COLOR_RESET}"
echo
echo "Downloading..."

# Download Tomcat
wget --quiet -O ${DOWNLOAD_PATH} $TOMCAT_URL
if [ "x$?" != "x0" ]; then
	echo -e "${COLOR_FAILURE}Failed to download Tomcat${COLOR_RESET}"
	exit 1;
fi

echo -e "${COLOR_SUCCESS}Download succeeded.${COLOR_RESET} You should verify that the correct package has been downloaded."

echo -ne "\n${COLOR_BOLD}Update the RPM spec file to the latest version [y/n]? ${COLOR_RESET}"
read UPDATE

if [ "x$UPDATE" == "xy" ] || [ "x$UPDATE" == "xY" ]; then
	SPEC_PATH_1=${OUR_PATH}/SPECS/uostomcat.spec
	#SPEC_PATH_2=${OUR_PATH}/SPECS/uostomcatnative.spec

	# Get the version currently in the spec file
	OLD_SPEC_VERSION=$(grep -E "^\s*%define\s+tomcat_version\s+" ${SPEC_PATH_1} | sed -r 's/^\s*%define\s+tomcat_version\s+//;s/\s*$//')

	# Update the spec file tomcat_version line
	sed -ri "s/^(\s*%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${TOMCAT_VERSION}/" ${SPEC_PATH_1}
	if [ "x$?" != "x0" ]; then
		echo -e "${COLOR_FAILURE}RPM spec file update failed${COLOR_RESET}"
		exit 1
	fi
	#sed -ri "s/^(\s*%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${TOMCAT_VERSION}/" ${SPEC_PATH_2}
	#if [ "x$?" != "x0" ]; then
	#	echo -e "${COLOR_FAILURE}RPM spec file update failed${COLOR_RESET}"
	#	exit 1
	#fi

	# If the version in the spec file has changed we should reset the 
	# release back to 1
	if [ "x${OLD_SPEC_VERSION}" != "x${TOMCAT_VERSION}" ]; then
		echo "Previous spec file tomcat_version was ${OLD_SPEC_VERSION}. Resetting tomcat_release to 1."
		sed -ri "s/^(\s*%define\s+tomcat_release\s+)[^\s]+\s*/\11/" ${SPEC_PATH_1}
		if [ "x$?" != "x0" ]; then
			echo -e "${COLOR_FAILURE}RPM spec file update failed${COLOR_RESET}"
			exit 1
		fi
		#sed -ri "s/^(\s*%define\s+tomcat_release\s+)[^\s]+\s*/\11/" ${SPEC_PATH_2}
		#if [ "x$?" != "x0" ]; then
		#	echo -e "${COLOR_FAILURE}RPM spec file update failed${COLOR_RESET}"
		#	exit 1
		#fi
	fi

	echo -ne "${COLOR_BOLD}Build updated RPMs [y/n]? ${COLOR_RESET}"
	read BUILD

	if [ "x$BUILD" == "xy" ] || [ "x$BUILD" == "xY" ]; then
		${OUR_PATH}/build.sh

		echo -ne "${COLOR_BOLD}Push to RHN [y/n]? ${COLOR_RESET}"
		read PUSH

		if [ "x$PUSH" == "xy" ] || [ "x$PUSH" == "xY" ]; then
			${OUR_PATH}/push.sh
		fi
	fi
fi
