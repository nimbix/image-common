#!/bin/bash -ex

# assumes install-centos-tiger.sh was run first

# update links
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"
wget --content-disposition -O - "$REALVNC"|tar -C /tmp -xzf -
rm -f /usr/bin/Xvnc
yum -y install /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm
ln -s /usr/bin/Xvnc-realvnc /usr/bin/Xvnc

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=`pwd`
cp -f $dirname/help-real.html /etc/NAE/help.html

