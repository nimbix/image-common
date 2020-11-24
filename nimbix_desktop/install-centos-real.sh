#!/bin/bash -ex

# update links
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"

# Download the tarball of RPMs and un-archive to retrieve the RPMs
wget --content-disposition -O - "$REALVNC"|tar -C /tmp -xzf -

# Install the server RPM into default location
rpm -Uvh /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=$(pwd)
mkdir -p /etc/NAE
#cp "$dirname"/help-real.html /etc/NAE/help.html
cp "$dirname"/help-real.html /etc/NAE/
