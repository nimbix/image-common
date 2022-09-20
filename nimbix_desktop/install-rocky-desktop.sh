#!/bin/bash -ex

ARCH=$(arch)

## Adding a safe download backup since SourceForge goes offline frequently
VGL64VER=2.6.5
VGL64="https://storage.googleapis.com/app_archive/virtualgl/VirtualGL-${VGL64VER}.x86_64.rpm"
VGL32="https://storage.googleapis.com/app_archive/virtualgl/VirtualGL-${VGL64VER}.i386.rpm"

dirname=$(dirname "$0")

# Get CentOS release version
#VERSION_ID=$(awk -F: '{print $5}' /etc/system-release-cpe)

# Required packages
dnf install -y epel-release
dnf install -y https://pkgs.dyn.su/el8/base/x86_64/raven-release-1.0-3.el8.noarch.rpm
dnf --enablerepo=epel group
dnf config-manager --set-enabled powertools
dnf groupinstall -y Xfce
dnf install -y perl wget xauth pygtk2 gnome-icon-theme  \
       xorg-x11-fonts-Type1 xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi \
       xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi \
       xkeyboard-config xorg-x11-apps xcb-util xcb-util-keysyms xorg-x11-utils \
       net-tools glx-utils ImageMagick-devel firefox \
       ristretto xterm python3-numpy python3-gobject python3-pip

# Dropped compat-libstdc++-33 as it is only for getting codes org built on rhel4 and rhel5 to work...

if [ "$ARCH" != "x86_64" ]; then
    echo "non-x86_64 has no VirtualGL"
else

    # Fix newer installs that put binary in /usr/libexec
#    if [[ -x /usr/libexec/vncserver ]]; then
#      ln -sf /usr/libexec/vncserver /usr/bin/vncserver
#    fi

    cd /tmp
    wget --content-disposition "$VGL64"
    wget --content-disposition "$VGL32"
    dnf -y install VirtualGL*.rpm || dnf -y update VirtualGL*.rpm
    rm -f VirtualGL*.rpm
fi

yum clean all

python3 -m pip install --no-cache-dir Wand

[ -f /etc/init.d/NetworkManager ] && /sbin/chkconfig NetworkManager off
[ -f /etc/xdg/autostart/xfce-polkit.desktop ] && \
    rm -f /etc/xdg/autostart/xfce-polkit.desktop

. $dirname/postinstall-desktop.sh
