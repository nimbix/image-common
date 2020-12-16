#!/bin/bash -ex

VERSION=1.9.0
ARCH=$(arch)

if [ "$ARCH" != "x86_64" ]; then
    #build_and_install_tiger
    if [[ -f /etc/redhat-release ]]; then
        yum -y install tigervnc-server
    else
        apt-get -y update
        apt-get -y install tigervnc-standalone-server
    fi
else
    # Install the cached tarball
    sudo tar -C / -xzf  /usr/local/lib/nimbix_desktop/tigervnc-$VERSION.$ARCH.tar.gz --strip-components=1

    # Fix newer installs that put binary in /usr/libexec
#    if [[ -x /usr/libexec/vncserver ]]; then
#      ln -sf /usr/libexec/vncserver /usr/bin/vncserver
#    fi

fi

sudo cp /usr/local/lib/nimbix_desktop/help-tiger.html /etc/NAE/help.html
