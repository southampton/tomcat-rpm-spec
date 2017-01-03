#!/bin/sh

# Check that we're not running as root!
if [ `id -u` == "0" ]; then
	echo "Do NOT run this script as root. Switch to the makerpm user first."
	exit 1;
fi

# Default to signing, but allow us not to
if [ "x$1" == "x--no-sign" ]; then
	SIGN=""
else
	SIGN="--sign"
fi

# Figure out the fully-qualified path of this script
BASEDIR=$(dirname $(readlink -f $0))

# Call rpmbuild, defining _topdir to be the fully qualified path to the 
# directory containing this script (which has an rpm buildroot in it)
/bin/rpmbuild $SIGN --define "_topdir $BASEDIR" -bb $BASEDIR/SPECS/uostomcat.spec
