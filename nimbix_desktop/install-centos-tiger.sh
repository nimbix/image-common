#!/bin/bash -ex

#VERSION=1.10.1
VERSION=master
ARCH=$(arch)

# update links as needed
#TIGERVNC="https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-$VERSION.$ARCH.tar.gz"
#TIGERSRC="https://github.com/TigerVNC/tigervnc/archive/v$VERSION.tar.gz"
TIGERSRC="https://github.com/TigerVNC/tigervnc/archive/master.tar.gz"
TIGERVNC="https://files.jarvice.io/archive/tigervnc/tigervnc-1.10.1-5.el8.x86_64.rpm"

#XORGVER=1.18.4
XORGVER=1.17.4
XORGSRC="https://www.x.org/archive//individual/xserver/xorg-server-$XORGVER.tar.gz"

# Adding a safe download backup since SourceForge goes offline frequently
VGL64VER=2.6.3
#VGL64="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-${VGL64VER}.x86_64.rpm"
VGL64="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.x86_64.rpm"
VGL32="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.i386.rpm"
#VGL32="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-${VGL64VER}.i386.rpm"

dirname=$(dirname $0)

# Get CentOS release version
VERSION_ID=$(cat /etc/system-release-cpe | awk -F: '{print $5}')

if [ $VERSION_ID -gt 7 ]; then
    dnf --enablerepo=epel group -y install "Xfce" "base-x" "Fonts"
    dnf -y install perl wget pygtk2 firefox net-tools ImageMagick \
           python2-numpy xorg-x11-fonts-Type1 \
           xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi \
           xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi

       #xauth gnome-icon-theme xkeyboard-config glx-utils xorg-x11-utils
       # compat-libstdc++-33 numpy python-pip ImageMagick-devel xorg-x11-apps xcb-util xcb-util-keysyms
else  # CentOS 8
  yum -y groupinstall Xfce
  yum -y groupinstall Fonts
  yum -y install perl wget xauth pygtk2 gnome-icon-theme xorg-x11-fonts-Type1 \
         xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi \
         xkeyboard-config firefox net-tools glx-utils xorg-x11-utils \
         xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi \
         compat-libstdc++-33 numpy python-pip ImageMagick-devel xorg-x11-apps \
         xcb-util xcb-util-keysyms
fi

function build_and_install_tiger() {
    dnf --enablerepo=PowerTools -y install git cmake make gcc-c++ \
        libX11-devel zlib-devel turbojpeg-devel libjpeg-turbo-devel \
        gnutls-devel gettext fltk-devel libXrender-devel autoconf automake \
        libtool pkgconfig bison flex gperf m4 ncurses-devel intltool \
        llvm libtalloc-devel mesa-libgbm-devel mtdev-devel libgcrypt-devel \
        pam-devel openssl-devel fontconfig libpng-devel freetype-devel imake \
        libXfont2-devel xorg-x11-server-devel pixman-devel xorg-x11-font-utils \
        xorg-x11-proto-devel xorg-x11-xtrans-devel libxkbfile-devel

    wget --content-disposition -O - "$TIGERSRC" |tar -C /tmp -xzf -
    TIGERVNC_SOURCE=/tmp/tigervnc-$VERSION
    BUILD_DIR=/tmp/tigervnc_build
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_VIEWER=OFF \
        $TIGERVNC_SOURCE
    make
    make install

    cp -R $TIGERVNC_SOURCE/unix/xserver $BUILD_DIR/unix/
    wget --content-disposition -O - "$XORGSRC" |tar -C /tmp -xzf -
    cp -R /tmp/xorg-server-$XORGVER/* $BUILD_DIR/unix/xserver/
    cd $BUILD_DIR/unix/xserver
    #patch -p1 < "$TIGERVNC_SOURCE/unix/xserver118.patch"
    patch -p1 < "$TIGERVNC_SOURCE/unix/xserver117.patch"
    autoreconf -fiv
    ./configure --prefix=/usr --with-pic --without-dtrace \
        --disable-static --disable-dri \
        --disable-xinerama --disable-xvfb --disable-xnest --disable-xorg \
        --disable-dmx --disable-xwin --disable-xephyr --disable-kdrive \
        --disable-config-hal --disable-config-udev \
        --disable-config-dbus --enable-install-libxf86config \
        --disable-dri2 --enable-glx \
        --with-default-font-path="catalogue:/etc/X11/fontpath.d,built-ins" \
        --with-fontdir=/usr/share/X11/fonts \
        --with-xkb-path=/usr/share/X11/xkb \
        --with-xkb-output=/var/lib/xkb \
        --with-xkb-bin-directory=/usr/bin \
        --with-dri-driver-path=/usr/lib/dri \
        --with-serverconfig-path=/usr/lib/xorg
    make TIGERVNC_SRCDIR=$TIGERVNC_SOURCE install


# TigerVNC build instrux
#      > cd {build_directory}
#
#    If performing an out-of-tree build:
#  > mkdir unix
#  > cp -R {source_directory}/unix/xserver unix/
#
#  > cp -R {xorg_source}/* unix/xserver/
#    (NOTE: {xorg_source} is the directory containing the Xorg source for the
#    machine on which you are building TigerVNC.  The most recent versions of
#    Red Hat/CentOS/Fedora, for instance, provide an RPM called
#    "xorg-x11-server-source", which installs the Xorg source under
#    /usr/share/xorg-x11-server-source.)
#
#  > cd unix/xserver/
#  > patch -p1 < {source_directory}/unix/xserver{version}.patch
#    (where {version} matches the X server version you are building, such as
#    "120" for version 1.20.x.)
#  > autoreconf -fiv
#
#  > ./configure --with-pic --without-dtrace --disable-static --disable-dri \
#      --disable-xinerama --disable-xvfb --disable-xnest --disable-xorg \
#      --disable-dmx --disable-xwin --disable-xephyr --disable-kdrive \
#      --disable-config-dbus --disable-config-hal --disable-config-udev \
#      --disable-dri2 --enable-install-libxf86config --enable-glx \
#      --with-default-font-path="catalogue:/etc/X11/fontpath.d,built-ins" \
#      --with-fontdir=/usr/share/X11/fonts \
#      --with-xkb-path=/usr/share/X11/xkb \
#      --with-xkb-output=/var/lib/xkb \
#      --with-xkb-bin-directory=/usr/bin \
#      --with-serverconfig-path=/usr/lib[64]/xorg \
#      --with-dri-driver-path=/usr/lib[64]/dri \
#      {additional configure options}
#    (NOTE: This is merely an example that works with Red Hat Enterprise/CentOS
#    6 and recent Fedora releases.  You should customize it for your particular
#    system.  In particular, it will be necessary to customize the font, XKB,
#    and DRI directories.)
#
#  > make TIGERVNC_SRCDIR={source_directory}

    #wget --content-disposition -O - "$VGL64SRC" |tar -C /tmp -xzf -
    #VGL64_SOURCE=/tmp/VirtualGL-$VGL64VER
    #BUILD_DIR=/tmp/vgl64_build
    #mkdir -p $BUILD_DIR
    #cd $BUILD_DIR
    #cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr \
    #    -DTJPEG_LIBRARY="-L/usr/lib64 -lturbojpeg" $VGL64_SOURCE
    #make
    #make install
}

if [ $VERSION_ID -gt 6 ]; then
    yum -y install ristretto
fi

if [ "$ARCH" != "x86_64" ]; then
    #build_and_install_tiger
    dnf -y install tigervnc-server VirtualGL
else
    # try upstream tiger
#    build_and_install_tiger

    # Grab newer binary packages on x86_64
#    wget --content-disposition -O - "$TIGERVNC" |tar -C / -xzf - --strip-components=1
#    dnf -y install tigervnc-server

    cd /tmp
    wget --content-disposition $TIGERVNC
    dnf -y install tigervnc-server
    wget --content-disposition "$VGL64"
    wget --content-disposition "$VGL32"
    dnf -y install VirtualGL*.rpm || dnf -y update VirtualGL*.rpm
    rm -f VirtualGL*.rpm
fi

yum clean all

pip2 install --no-cache-dir Wand

[ -f /etc/init.d/NetworkManager ] && /sbin/chkconfig NetworkManager off
# TODO: check relevance on C8
[ -f /etc/xdg/autostart/xfce-polkit.desktop ] && \
    rm -f /etc/xdg/autostart/xfce-polkit.desktop

. $dirname/postinstall-tiger.sh
