#!/bin/bash

set -e
set -x

[ "$1" = "--setup-nimbix-desktop" ] && SETUP_NIMBIX_DESKTOP=1

ETC_HOSTS="$(cat <<EOF
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
EOF
)"

INIT_FAKE_CONF="$(cat <<EOF
# fake some events needed for correct startup other services
description     "In-Container Upstart Fake Events"
start on startup
script
    rm -rf /var/run/*.pid
    rm -rf /var/run/network/*
    /sbin/initctl emit stopped JOB=udevtrigger --no-wait
    /sbin/initctl emit started JOB=udev --no-wait
    /sbin/initctl emit runlevel RUNLEVEL=3 --no-wait
end script
EOF
)"

[ -e /etc/system-release-cpe ] && \
    VERSION_ID=$(cat /etc/system-release-cpe | awk -F: '{print $5}')

# Base OS
function setup_base_os() {
    PKGS="curl zip unzip sudo"
    if [ -f /etc/redhat-release ]; then
        PKGS+=" passwd xz tar file openssh-server infiniband-diags"
        PKGS+=" openmpi perftest libibverbs-utils libmthca libcxgb4 libmlx4"
        PKGS+=" libmlx5 dapl compat-dapl dap.i686 compat-dapl.i686 which"
        yum -y update
        yum -y install $PKGS
        yum clean all

        rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
        if [ $VERSION_ID -gt 6 ]; then
            echo '# leave empty' >/etc/fstab
        else
            echo '/dev/root / rootfs defaults 0 0' >/etc/fstab
            sed -i 's|.sbin.start_udev||' /etc/rc.sysinit
            sed -i 's|.sbin.start_udev||' /etc/rc.d/rc.sysinit
            chkconfig udev-post off
            echo "$ETC_HOSTS" >/etc/hosts
        fi

    else # Ubuntu
        # upstart fixes
        # init-fake.conf from https://raw.githubusercontent.com/tianon/dockerfiles/master/sbin-init/ubuntu/upstart/14.04/init-fake.conf
        echo "$INIT_FAKE_CONF" >/etc/init/fake-container-events.conf
        rm -f /usr/sbin/policy-rc.d /sbin/initctl
        dpkg-divert --rename --remove /sbin/initctl
        echo '# /lib/init/fstab: cleared out for bare-bones Docker' \
            >/lib/init/fstab

        touch /etc/init.d/systemd-logind

        export DEBIAN_FRONTEND noninteractive
        PKGS+=" module-init-tools xz-utils vim openssh-server libpam-systemd"
        PKGS+=" libmlx4-1 libmlx5-1 iptables infiniband-diags build-essential"
        PKGS+=" libibverbs-dev libibverbs1 librdmacm1 librdmacm-dev"
        PKGS+=" rdmacm-utils libibmad-dev libibmad5 byacc flex git cmake"
        PKGS+=" screen grep locales net-tools"
        apt-get -y update
        apt-get -y install $PKGS
        apt-get clean
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8

        [ -f /etc/init/ssh.conf ] && \
            sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf

        echo "set -a" >/etc/profile.d/00-container-environment.sh
        env |grep -v ^HOSTNAME=|grep -v ^PWD=|grep -v \
            ^DEBIAN_FRONTEND=|grep -v ^HOME=|grep -v \
            ^SHLVL= >>/etc/profile.d/00-container-environment.sh
        echo "set +a" >>/etc/profile.d/00-container-environment.sh
    fi
}

# Nimbix JARVICE emulation
function setup_jarvice_emulation {
    cd /tmp
    curl https://codeload.github.com/nimbix/image-common/zip/master \
        >/tmp/nimbix.zip
    unzip nimbix.zip
    rm -f nimbix.zip
    /tmp/image-common-master/setup-nimbix.sh

    mkdir -p /usr/lib/JARVICE
    cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
    ln -s /usr/lib/JARVICE/tools/noVNC/images/favicon.png \
        /usr/lib/JARVICE/tools/noVNC/favicon.png
    ln -s /usr/lib/JARVICE/tools/noVNC/images/favicon.png \
        /usr/lib/JARVICE/tools/noVNC/favicon.ico
    cd /usr/lib/JARVICE/tools/noVNC/utils
    ln -s websockify /usr/lib/JARVICE/tools/noVNC/utils/websockify.py
    ln -s websockify /usr/lib/JARVICE/tools/noVNC/utils/wsproxy.py
    cd /tmp
    cp -a /tmp/image-common-master/etc /etc/JARVICE
    chmod 755 /etc/JARVICE
    mkdir -m 0755 -p /data
    chown nimbix:nimbix /data
}

function setup_nimbix_desktop() {
    mkdir -p /usr/local/lib/nimbix_desktop
    if [ -f /etc/redhat-release ]; then
        files="install-centos-tiger.sh"
        files+=" install-centos-real.sh help-real.html"
    else
        files="install-ubuntu-tiger.sh"
    fi
    files+=" help-tiger.html postinstall-tiger.sh"
    files+=" nimbix_desktop url.txt xfce4-session-logout share skel.config"
    for i in $files; do
        cp -a /tmp/image-common-master/nimbix_desktop/$i \
            /usr/local/lib/nimbix_desktop
    done
    if [ -f /etc/redhat-release ]; then
        /usr/local/lib/nimbix_desktop/install-centos-tiger.sh
        yum clean all
        echo "/usr/local/bin/nimbix_desktop" >>/etc/rc.local
    else
        /usr/local/lib/nimbix_desktop/install-ubuntu-tiger.sh
    fi

    ln -s /usr/local/lib/nimbix_desktop /usr/lib/JARVICE/tools/nimbix_desktop

    # recreate nimbix user home to get the right skeleton files
    /bin/rm -rf /home/nimbix
    /sbin/mkhomedir_helper nimbix
}

function cleanup() {
    rm -rf /tmp/image-common-master
}

setup_base_os
setup_jarvice_emulation
[ -n "$SETUP_NIMBIX_DESKTOP" ] && setup_nimbix_desktop
cleanup

exit 0
