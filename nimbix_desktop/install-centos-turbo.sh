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

#Package curl-7.29.0-51.el7.x86_64 already installed and latest version
#Package passwd-0.79-4.el7.x86_64 already installed and latest version
#Package xz-5.2.2-1.el7.x86_64 already installed and latest version
#Package 2:tar-1.26-35.el7.x86_64 already installed and latest version
#No package dap.i686 available.
#No package shellinabox available.
#Package 4:perl-5.16.3-294.el7_6.x86_64 already installed and latest version
#Package 1:xorg-x11-xauth-1.0.9-1.el7.x86_64 already installed and latest version
#Package gnome-icon-theme-3.12.0-1.el7.noarch already installed and latest version
#Package xkeyboard-config-2.24-1.el7.noarch already installed and latest version
#Package glx-utils-8.3.0-10.el7.x86_64 already installed and latest version
#Package xcb-util-0.4.0-2.el7.x86_64 already installed and latest version

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
    cd /tmp
    wget --content-disposition "$TURBOVNC"
    yum -y install turbovnc*.rpm
    rm -f turbovnc*.rpm
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
