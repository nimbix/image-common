#!/bin/bash -ex

#VERSION=1.11.0
VERSION=1.9.0
ARCH=$(arch)

# update links as needed
TIGERVNC="https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-$VERSION.$ARCH.tar.gz"
TIGERSRC="https://github.com/TigerVNC/tigervnc/archive/v$VERSION.tar.gz"

#XORGVER=1.18.4
XORGVER=1.17.4
XORGSRC="https://www.x.org/archive//individual/xserver/xorg-server-$XORGVER.tar.gz"

# Adding a safe download backup since SourceForge goes offline frequently
VGL64VER=2.6.3
VGL64="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.x86_64.rpm"
VGL32="https://files.jarvice.io/archive/virtualgl/VirtualGL-${VGL64VER}.i386.rpm"
#VGL64SRC="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-$VGL64VER.tar.gz"

dirname=$(dirname "$0")

# Get CentOS release version
#VERSION_ID=$(awk -F: '{print $5}' /etc/system-release-cpe)

function build_and_install_tiger() {
    yum -y install git cmake make gcc-c++ \
        libX11-devel zlib-devel turbojpeg-devel libjpeg-turbo-devel \
        gnutls-devel gettext fltk-devel libXrender-devel autoconf automake \
        libtool pkgconfig bison flex gperf m4 ncurses-devel intltool \
        llvm libtalloc-devel mesa-libgbm-devel mtdev-devel libgcrypt-devel \
        openssl-devel fontconfig libpng-devel freetype-devel imake \
        libXfont-devel xorg-x11-server-devel pixman-devel xorg-x11-font-utils \
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
        --disable-dri2 --enable-glx \
        --with-xkb-path=/usr/share/X11/xkb \
        --with-xkb-output=/var/lib/xkb \
        --with-xkb-bin-directory=/usr/bin \
        --with-serverconfig-path=/usr/lib/xorg
    make TIGERVNC_SRCDIR=$TIGERVNC_SOURCE install

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

yum -y groupinstall Xfce
yum -y install perl wget xauth pygtk2 gnome-icon-theme  \
       xorg-x11-fonts-Type1 xorg-x11-fonts-misc xorg-x11-fonts-75dpi xorg-x11-fonts-100dpi \
       xorg-x11-fonts-ISO8859-1-100dpi xorg-x11-fonts-ISO8859-1-75dpi \
       xkeyboard-config xorg-x11-apps xcb-util xcb-util-keysyms xorg-x11-utils \
       net-tools glx-utils ImageMagick-devel firefox \
       compat-libstdc++-33 ristretto xterm numpy python-pip

if [ "$ARCH" != "x86_64" ]; then
    #build_and_install_tiger
    yum -y install tigervnc-server VirtualGL
else
    # Grab newer binary packages on x86_64, install in place to an location that needs pathing
    wget --content-disposition -O - "$TIGERVNC" | tar -C /usr/local -xzf - --strip-components=2

    # Fix newer installs that put binary in /usr/libexec
#    if [[ -x /usr/libexec/vncserver ]]; then
#      ln -sf /usr/libexec/vncserver /usr/bin/vncserver
#    fi

    cd /tmp
    wget --content-disposition "$VGL64"
    wget --content-disposition "$VGL32"
    yum -y install VirtualGL*.rpm || yum -y update VirtualGL*.rpm
    rm -f VirtualGL*.rpm
fi

yum clean all

pip install --no-cache-dir Wand

[ -f /etc/init.d/NetworkManager ] && /sbin/chkconfig NetworkManager off
[ -f /etc/xdg/autostart/xfce-polkit.desktop ] && \
    rm -f /etc/xdg/autostart/xfce-polkit.desktop

. $dirname/postinstall-tiger.sh
