#!/bin/bash -ex

VERSION=1.7.1
ARCH=$(arch)

# update links as needed
TIGERVNC="https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-$VERSION.$ARCH.tar.gz"
TIGERSRC="https://github.com/TigerVNC/tigervnc/archive/v$VERSION.tar.gz"

XORGVER=1.18.4
XORGSRC="https://www.x.org/archive//individual/xserver/xorg-server-$XORGVER.tar.gz"

VGL64VER=2.5
VGL64="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/virtualgl_${VGL64VER}_amd64.deb"
VGL64SRC="https://downloads.sourceforge.net/project/virtualgl/$VGL64VER/VirtualGL-$VGL64VER.tar.gz"
dirname=$(dirname $0)

function build_and_install_tiger() {
    apt-get -y install git cmake libx11-dev zlib1g-dev libjpeg-turbo8-dev \
        gettext libfltk1.3-dev libxrender-dev autoconf automake autopoint \
        libtool pkg-config bison flex gperf m4 libncurses5-dev \
        intltool llvm libtalloc-dev libgbm1 libmtdev-dev libgcrypt20-dev \
        libssl-dev libmd-dev fontconfig libpng-dev libfreetype6-dev \
        xutils-dev xfonts-utils xserver-xorg-dev libpixman-1-dev \
        x11proto-record-dev x11proto-xcmisc-dev x11proto-bigreqs-dev \
        x11proto-composite-dev libjpeg-turbo8 libjpeg-turbo8-dev \
        libxfont1-dev
    wget --content-disposition -O - "$TIGERSRC" |tar -C /tmp -xzf -
    TIGERVNC_SOURCE=/tmp/tigervnc-$VERSION
    BUILD_DIR=/tmp/tigervnc_build
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr $TIGERVNC_SOURCE
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

    wget --content-disposition -O - "$VGL64SRC" |tar -C /tmp -xzf -
    VGL64_SOURCE=/tmp/VirtualGL-$VGL64VER
    BUILD_DIR=/tmp/vgl64_build
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    DEB_HOST_GNU_TYPE=$(dpkg-architecture -f -qDEB_HOST_GNU_TYPE 2>/dev/null)
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr \
        -DTJPEG_LIBRARY="-L/usr/lib/$DEB_HOST_GNU_TYPE \
        -lturbojpeg" $VGL64_SOURCE
    make
    make install
}

export DEBIAN_FRONTEND=noninteractive
#apt-get -y update
#apt-get -y install software-properties-common
#add-apt-repository -y ppa:canonical-x/x-staging  # latest xorg server
apt-get -y update
apt-get -y install librtmp0 || apt-get -y install librtmp1
apt-get -y install wget gnome-icon-theme-full \
    humanity-icon-theme tango-icon-theme xfce4 xfce4-terminal \
    fonts-freefont-ttf xfonts-base xfonts-100dpi xfonts-75dpi x11-apps \
    xfonts-scalable xauth firefox ristretto mesa-utils init-system-helpers

if [ "$ARCH" != "x86_64" ]; then
    build_and_install_tiger
else
    wget --content-disposition -O - "$TIGERVNC" |tar -C / -xzf - --strip-components=1

    cd /tmp
    wget --content-disposition "$VGL64"
    dpkg --install virtualgl*.deb || apt-get -f install
    rm -f virtualgl*.deb
fi

PY2=`python -V 2>&1 |grep "^Python 2" || true`
if [ -n "$PY2" ]; then

    # this clobbers py3 only, so do it only if we have py2
    apt-get -y install libmagickwand-dev

    # pip is too old on trusty to drop cache
    UBUVER=$(lsb_release -sr)
    if [[ ${UBUVER} == 14.04 ]]; then
        pip install Wand
    else
        pip install --no-cache-dir Wand
    fi
fi

apt-get clean

. $dirname/postinstall-tiger.sh
