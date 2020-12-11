#!/bin/bash -ex

#BINVERSION=1.11.0
BINVERSION=1.9.0
ARCH=$(arch)
SRCVERSION=1.8.0

# update links as needed
TIGERVNC="https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-$BINVERSION.$ARCH.tar.gz"
TIGERSRC="https://github.com/TigerVNC/tigervnc/archive/v$SRCVERSION.tar.gz"

XORGVER=1.18.4
XORGSRC="https://www.x.org/archive//individual/xserver/xorg-server-$XORGVER.tar.gz"

# Adding a safe download backup since SourceForge goes offline frequently
VGL64VER=2.6.3
#VGL64="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/virtualgl_${VGL64VER}_amd64.deb"
VGL64="https://files.jarvice.io/archive/virtualgl/virtualgl_${VGL64VER}_amd64.deb"
#VGL64SRC="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-$VGL64VER.tar.gz"
dirname=$(dirname $0)

function build_and_install_tiger() {
    apt-get -y install build-essential git cmake libx11-dev zlib1g-dev \
        gettext libfltk1.3-dev libxrender-dev autoconf automake autopoint \
        libtool pkg-config bison flex gperf m4 libncurses5-dev \
        intltool llvm libtalloc-dev libgbm1 libmtdev-dev libgcrypt20-dev \
        libssl-dev libmd-dev fontconfig libpng-dev libfreetype6-dev \
        xutils-dev xfonts-utils xserver-xorg-dev libpixman-1-dev \
        x11proto-record-dev x11proto-xcmisc-dev x11proto-bigreqs-dev \
        x11proto-composite-dev libjpeg-turbo8 libjpeg-turbo8-dev  \
        libxfont1-dev libxaw7-dev perl-modules xfonts-base \
        libxau-dev libxext-dev libxi-dev libxkbfile-dev libxmu-dev libxt-dev \
        x11proto-core-dev libgnutls-dev libpam0g-dev libpng12-dev \
        x11proto-damage-dev x11proto-dri2-dev x11proto-fixes-dev \
        x11proto-fonts-dev x11proto-gl-dev x11proto-input-dev x11proto-kb-dev \
        x11proto-randr-dev x11proto-render-dev x11proto-resource-dev \
        x11proto-scrnsaver-dev x11proto-video-dev x11proto-xext-dev \
        x11proto-xf86bigfont-dev x11proto-xf86dga-dev x11proto-xf86dri-dev \
        x11proto-xf86vidmode-dev x11proto-xinerama-dev libosmesa6-dev \
        libgl1-mesa-dev libgl1-mesa-dri libgl1-mesa-glx libxfont-dev \
        default-jdk libxtst-dev libxft-dev libexpat1-dev libfontconfig1-dev \
        libpciaccess-dev curl bzip2 quilt libglu1-mesa-dev libxcursor-dev \
        libxinerama-dev libxfixes-dev libcairo2-dev x11proto-dri3-dev \
        x11proto-present-dev xorg-server-source fluid
    wget --content-disposition -O - "$TIGERSRC" |tar -C /tmp -xzf -
    TIGERVNC_SOURCE=/tmp/tigervnc-${SRCVERSION}
    BUILD_DIR=/tmp/tigervnc_build
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr ${TIGERVNC_SOURCE}
    make
    make install

    cp -R $TIGERVNC_SOURCE/unix/xserver $BUILD_DIR/unix/
    wget --content-disposition -O - "$XORGSRC" |tar -C /tmp -xzf -
    cp -R /tmp/xorg-server-$XORGVER/* $BUILD_DIR/unix/xserver/
    cd $BUILD_DIR/unix/xserver
    patch -p1 < "$TIGERVNC_SOURCE/unix/xserver118.patch"
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

    # Don't compile a VirtualGL for non-X86-64 arches
#    wget --content-disposition -O - "$VGL64SRC" |tar -C /tmp -xzf -
#    VGL64_SOURCE=/tmp/VirtualGL-$VGL64VER
#    BUILD_DIR=/tmp/vgl64_build
#    mkdir -p $BUILD_DIR
#    cd $BUILD_DIR
#    DEB_HOST_GNU_TYPE=$(dpkg-architecture -f -qDEB_HOST_GNU_TYPE 2>/dev/null)
#    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr \
#        -DTJPEG_LIBRARY="-L/usr/lib/$DEB_HOST_GNU_TYPE \
#        -lturbojpeg" $VGL64_SOURCE
#    make
#    make install
}

export DEBIAN_FRONTEND=noninteractive
apt-get -y update

apt-get -y install wget gnome-icon-theme software-properties-common \
    humanity-icon-theme tango-icon-theme xfce4 xfce4-terminal \
    fonts-freefont-ttf xfonts-base xfonts-100dpi xfonts-75dpi x11-apps \
    xfonts-scalable xauth firefox ristretto mesa-utils init-system-helpers \
    libxcb1 libxcb-keysyms1 libxcb-util1 librtmp1 python-numpy

if [[ "$ARCH" != "x86_64" ]]; then
    build_and_install_tiger
else
    wget --content-disposition -O - "$TIGERVNC" | tar -C / -xzf - --strip-components=1

    # Fix newer installs that put binary in /usr/libexec
#    if [[ -x /usr/libexec/vncserver ]]; then
#      ln -sf /usr/libexec/vncserver /usr/bin/vncserver
#    fi

    cd /tmp
    wget --content-disposition "$VGL64"
    dpkg --install virtualgl*.deb || apt-get -f install
    rm -f virtualgl*.deb
fi

PY2=$(python -V 2>&1 |grep "^Python 2" || true)
if [[ -n "$PY2" ]]; then

    # this clobbers py3 only, so do it only if we have py2
    apt-get -y install python-pip libmagickwand-dev python-gtk2 python-gnome2

    # Wand is used for screenshots
    pip install Wand
fi

apt-get clean

. $dirname/postinstall-tiger.sh
