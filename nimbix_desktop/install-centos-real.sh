#!/bin/bash -ex

INSTALLPATH=/usr/local/realvnc

# update links
#REALVNC_VER=6.2.1
#REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-Server-$REALVNC_VER-Linux-x64.rpm"
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"

#VGL64VER=2.6.3
#VGL64="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.x86_64.rpm"
#VGL32="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.i386.rpm"
#VGL64SRC="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-$VGL64VER.tar.gz"

# Download the tarball of RPMs and un-archive
wget --content-disposition -O - "$REALVNC"|tar -C /tmp -xzf -
#  XXX rm -f /usr/bin/Xvnc
#yum -y install /tmp/VNC-Server-*-Linux-x64.rpm || \
#    yum -y update /tmp/VNC-Server-*-Linux-x64.rpm

# Install to alternate location, leaving Tiger as default, and not conflicting
#   by files
mkdir $INSTALLPATH
rpm -Uvh --prefix=$INSTALLPATH /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm
#  XXX ln -sf /usr/bin/Xvnc-realvnc /usr/bin/Xvnc

# TODO: find any effect of this error seen at install
#[91m/var/tmp/rpm-tmp.RXubfJ: line 338: vncinitconfig: command not found


dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=$(pwd)
mkdir -p /etc/NAE
#cp "$dirname"/help-real.html /etc/NAE/help.html
cp "$dirname"/help-real.html /etc/NAE/
