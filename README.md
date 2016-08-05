# tomcat-rpm-spec
RPM spec for Tomcat (currently 8.5, but can be use for future versions) on RHEL7

To use this, install rpmbuild and then build a rpm tree:

mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

place the contents of 'SPECS' and 'SOURCES' from this repo into the directories created above.

then download the latest version of Apache Tomcat and place the tar.gz in "SOURCES"

Adjust the uostomcat.spec file to match the version number you downloaded.

Then cd into SPECS and run:

rpmbuild -bb uostomcat.spec
