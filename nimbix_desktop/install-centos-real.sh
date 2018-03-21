#!/bin/bash -ex

# assumes install-centos-tiger.sh was run first

# update links
#REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"
REALVNC_VER=6.2.1
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-Server-$REALVNC_VER-Linux-x64.rpm"
wget --content-disposition -O /tmp/$(basename $REALVNC) "$REALVNC"
rm -f /usr/bin/Xvnc
yum -y install /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm
[ -e /usr/bin/Xvnc ] || ln -sf /usr/bin/Xvnc-realvnc /usr/bin/Xvnc

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=`pwd`
cp -f $dirname/help-real.html /etc/NAE/help.html

