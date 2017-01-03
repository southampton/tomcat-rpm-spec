#!/bin/bash

# Script configuration
RHNSERVER=rhn.soton.ac.uk
RHNCHANNEL=isolutions-dev-uos-packages-rhel7-server
ARCH=noarch
PACKAGE=uostomcat

# Helper variables
COLOR_BOLD="\e[1m"
COLOR_SUCCESS="\e[1;92m"
COLOR_FAILURE="\e[1;91m"
COLOR_RESET="\e[0m"

# Figure out the fully-qualified path of this script
BASEDIR=$(dirname $(readlink -f $0))

# Figure out path to RPMS
RPMDIR=${BASEDIR}/RPMS/${ARCH}

# Ensure some RPMs exist for the package and architecture, generally
ls -1 ${RPMDIR}/${PACKAGE}*.${ARCH}.rpm >/dev/null 2>/dev/null
if [ "x$?" != "x0" ]; then
	echo -e "${COLOR_FAILURE}Could not locate RPMs. Ensure the build has succeeded and that the ${RPMDIR} contains files${COLOR_RESET}"
	exit 1
fi

# If the user specifies a version on the command line then push that, otherwise
# figure out which RPMs to push
if [ "x$1" != "x" ]; then
	VERSION=$1
	AUTO=""
else
	VERSION=$(ls -1 ${RPMDIR} | grep -E "^${PACKAGE}-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.${ARCH}\.rpm\$" | sort -r | head -n 1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+')
	AUTO="auto-detected "
fi

# Print version information to user
echo -e "Pushing ${AUTO}version ${COLOR_SUCCESS}${VERSION}${COLOR_RESET}"
if [ "x$AUTO" != "x" ]; then
	echo "If this is not correct, specify the version on the command line."
fi
echo

# Ensure some RPMs exist for the version
ls -1 ${RPMDIR}/${PACKAGE}*-${VERSION}.${ARCH}.rpm >/dev/null 2>/dev/null
if [ "x$?" != "x0" ]; then
	echo -e "${COLOR_FAILURE}Could not locate RPMs. Ensure the build has succeeded and that the ${RPMDIR} contains files${COLOR_RESET}"
	exit 1
fi

# List the RPMs we're going to push, and verify that they are signed
echo -e "${COLOR_BOLD}RPMS being pushed:${COLOR_RESET}"
ALLSIGNED=1
while read RPM; do 
	echo "  $RPM"
	rpm -K $RPM | grep 'gpg OK$' >/dev/null 2>/dev/null
	if [ "x$?" != "x0" ]; then
		ALLSIGNED=0
		echo -e "  ${COLOR_FAILURE}- Package not signed${COLOR_RESET}"
	else
		echo -e "  ${COLOR_SUCCESS}- Package signed${COLOR_RESET}"
	fi
done < <(ls -1 ${RPMDIR}/${PACKAGE}*-${VERSION}.${ARCH}.rpm)
echo

# Abort if not all the packages were signed
if [ "x$ALLSIGNED" != "x1" ]; then
	echo -e  "${COLOR_FAILURE}Not all packages were signed. Aborting.${COLOR_RESET}"
	exit 1;
fi

# Get a username
echo -ne "${COLOR_BOLD}Satellite Username: ${COLOR_RESET}"
read RHNUSER

# Push!
rhnpush --server=${RHNSERVER} --username=${RHNUSER} --channel=${RHNCHANNEL} ${RPMDIR}/${PACKAGE}*-${VERSION}.${ARCH}.rpm 
