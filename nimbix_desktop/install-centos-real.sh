#!/bin/bash -ex

# assumes install-centos-tiger.sh was run first

# update links
#REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"
REALVNC_VER=6.2.1
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-Server-$REALVNC_VER-Linux-x64.rpm"

yum -y groupinstall Xfce
yum -y groupinstall Fonts
yum -y install perl wget xauth pygtk2 gnome-icon-theme xorg-x11-fonts-Type1 xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi xkeyboard-config firefox net-tools glx-utils xorg-x11-utils
yum -y install xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi compat-libstdc++-33
if [ $VERSION_ID -gt 6 ]; then
    yum -y install ristretto
fi

curl $REALVNC >/tmp/$(basename $REALVNC)
rm -f /usr/bin/Xvnc
yum -y install /tmp/VNC-Server-*-Linux-x64.rpm || \
    yum -y update /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm
ln -sf /usr/bin/Xvnc-realvnc /usr/bin/Xvnc

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=`pwd`
mkdir -p /etc/NAE
cp $dirname/help-real.html /etc/NAE/help.html

yum clean all
[ -f /etc/init.d/NetworkManager ] && /sbin/chkconfig NetworkManager off
[ -f /etc/xdg/autostart/xfce-polkit.desktop ] && \
    rm -f /etc/xdg/autostart/xfce-polkit.desktop

