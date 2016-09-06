#!/bin/bash -ex

# update links as needed
TIGERVNC="https://bintray.com/artifact/download/tigervnc/stable/tigervnc-Linux-x86_64-1.6.0.tar.gz"
VGL64="https://sourceforge.net/projects/virtualgl/files/2.5/VirtualGL-2.5.x86_64.rpm/download"
VGL32="https://sourceforge.net/projects/virtualgl/files/2.5/VirtualGL-2.5.i386.rpm/download"
dirname=$(dirname $0)

VERSION_ID=$(cat /etc/system-release-cpe | awk -F: '{print $5}')
EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"
rpm -i $EPEL
yum -y groupinstall Xfce
yum -y groupinstall Fonts
yum -y install perl wget xauth pygtk2 gnome-icon-theme xorg-x11-fonts-Type1 xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi xkeyboard-config firefox net-tools glx-utils xorg-x11-utils
yum -y install xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi compat-libstdc++-33
wget --content-disposition -O - "$TIGERVNC" |tar -C / -xzf -
cd /tmp
wget --content-disposition "$VGL64"
wget --content-disposition "$VGL32"
yum -y install VirtualGL*.rpm
rm -f VirtualGL*.rpm
yum clean all
[ -f /etc/init.d/NetworkManager ] && /sbin/chkconfig NetworkManager off

. $dirname/postinstall-tiger.sh
