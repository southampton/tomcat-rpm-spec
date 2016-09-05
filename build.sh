#!/bin/sh

# Call rpmbuild, defining _topdir to be the fully qualified path to the 
# directory containing this script (which has an rpm buildroot in it)
/bin/rpmbuild --define "_topdir $(dirname $(readlink -f $0))" -bb SPECS/uostomcat.spec

