#!/bin/bash -ex

ARCH=$(arch)

# update links as needed
TURBOVER=2.2.1
TURBOVNC="https://downloads.sourceforge.net/project/turbovnc/$TURBOVER/turbovnc-${TURBOVER}.x86_64.rpm"

#XORGVER=1.18.4
#XORGVER=1.17.4
#XORGSRC="https://www.x.org/archive//individual/xserver/xorg-server-$XORGVER.tar.gz"

VGL64VER=2.6.1
VGL64="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-${VGL64VER}.x86_64.rpm"
VGL32="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-${VGL64VER}.i386.rpm"
VGL64SRC="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-$VGL64VER.tar.gz"

dirname=$(dirname $0)

# Get CentOS release version
VERSION_ID=$(cat /etc/system-release-cpe | awk -F: '{print $5}')

yum -y groupinstall Xfce
yum -y groupinstall Fonts
yum -y install perl wget xauth pygtk2 gnome-icon-theme xorg-x11-fonts-Type1 \
       xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi \
       xkeyboard-config firefox net-tools glx-utils xorg-x11-utils \
       xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi \
       compat-libstdc++-33 python-pip ImageMagick-devel xorg-x11-apps \
       xcb-util xcb-util-keysyms
if [[ ${VERSION_ID} -gt 6 ]]; then
    yum -y install ristretto
fi

if [[ "$ARCH" != "x86_64" ]]; then
    #build_and_install_turbo ???
    yum -y install turbovnc-server VirtualGL
else
    # Grab newer binary packages on x86_64
    wget --content-disposition -O - "TURBOVNC" |tar -C / -xzf - --strip-components=1
    cd /tmp
    wget --content-disposition "$VGL64"
    wget --content-disposition "$VGL32"
    yum -y install VirtualGL*.rpm || yum -y update VirtualGL*.rpm
    rm -f VirtualGL*.rpm
fi

yum clean all

pip install --no-cache-dir Wand

[[ -f /etc/init.d/NetworkManager ]] && /sbin/chkconfig NetworkManager off
[[ -f /etc/xdg/autostart/xfce-polkit.desktop ]] && \
    rm -f /etc/xdg/autostart/xfce-polkit.desktop

. ${dirname}/postinstall-turbo.sh
