#!/usr/bin/env bash

set -e
set -x

BRANCH=master

while [ $# -gt 0 ]; do
    case $1 in
        --setup-nimbix-desktop)
            SETUP_NIMBIX_DESKTOP=1
            shift
            ;;
        --setup-realvnc)
            SETUP_REALVNC=1
            shift
            ;;
        --disable-desktop-autostart)
            export DISABLE_DESKTOP_AUTOSTART=1
            shift
            ;;
        --skip-os-pkg-update)
            export SKIP_OS_PKG_UPDATE=1
            shift
            ;;
        --image-common-branch)
            BRANCH=$2
            shift; shift
            ;;
        *)
            break
            ;;
    esac
done

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
    VERSION_ID=$(awk -F: '{print $5}' /etc/system-release-cpe)

# Base OS
function setup_base_os() {
    #CentOS 8 specific
    if [[ -f /etc/redhat-release && $VERSION_ID == 8 ]]; then
#        PKGS="epel-release zip unzip infiniband-diags mailcap glibc-langpack-en"
#        PKGS+=" openmpi perftest libibverbs-utils libcxgb4 libmlx4 libmlx5"
##        PKGS+=" libmthca dapl compat-dapl dap.i686 compat-dapl.i686"
#        PKGS+=" python2"

        # Sometimes update will pick up unexpected new packages or deps
        [ -z "$SKIP_OS_PKG_UPDATE" ] && dnf -y update

        dnf -y install epel-release zip unzip infiniband-diags mailcap \
               glibc-langpack-en openmpi perftest libibverbs-utils libcxgb4 \
               libmlx4 libmlx5 python2 sudo openssh-server
        dnf clean all

        # Py 2 and 3 don't set a default, fix to py2 for scripts
        alternatives --set python /usr/bin/python2

        # Set locale
#        localedef -i en_US -f UTF-8 en_US.UTF-8

        echo '# leave empty' >/etc/fstab
    elif [ -f /etc/redhat-release ]; then  # CentOS 7 and 6
        PKGS="curl zip unzip sudo"
        if [ ! -f /etc/fedora-release ]; then
            PKGS+=" epel-release"
        fi
        PKGS+=" passwd xz tar file openssh-server infiniband-diags"
        PKGS+=" openmpi perftest libibverbs-utils libmthca libcxgb4 libmlx4"
        PKGS+=" libmlx5 dapl compat-dapl dapl.i686 compat-dapl.i686 which"
        PKGS+=" openssh-clients sshpass mailcap"
        [ -z "$SKIP_OS_PKG_UPDATE" ] && yum -y update
        yum -y install $PKGS
        yum clean all

        # Set locale
        localedef -i en_US -f UTF-8 en_US.UTF-8

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
    else # Ubuntu (assumed)

        # upstart fixes
        # init-fake.conf from https://raw.githubusercontent.com/tianon/dockerfiles/master/sbin-init/ubuntu/upstart/14.04/init-fake.conf
        [ -d /etc/init ] && \
            echo "$INIT_FAKE_CONF" >/etc/init/fake-container-events.conf
        rm -f /usr/sbin/policy-rc.d /sbin/initctl
        dpkg-divert --rename --remove /sbin/initctl
        echo '# /lib/init/fstab: cleared out for bare-bones Docker' \
            >/lib/init/fstab

        touch /etc/init.d/systemd-logind

        export DEBIAN_FRONTEND noninteractive
        PKGS="curl zip unzip sudo"
        PKGS+=" kmod xz-utils vim openssh-server libpam-systemd"
        PKGS+=" libmlx4-1 libmlx5-1 iptables infiniband-diags build-essential"
        PKGS+=" libibverbs-dev libibverbs1 librdmacm1 librdmacm-dev ibverbs-utils"
        PKGS+=" rdmacm-utils libibmad-dev libibmad5 byacc flex git cmake"
        PKGS+=" screen grep locales locales-all net-tools"
        PKGS+=" openssh-client sshpass"
        if [ ! -e /usr/bin/python ]; then
            PKGS+=" python python-pip"
        fi

        # unfortunately on Ubuntu we can't skip the apt-get update since
        # most images have broken cache, so we have to do it anyway
        #(was [ -z "$SKIP_OS_PKG_UPDATE" ] && apt-get -y update)
        apt-get -y update
        # XXX ^^^
        apt-get -y install $PKGS
        apt-get clean
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8

        [ -f /etc/init/ssh.conf ] && \
            sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf
    fi

    echo "set -a" >/etc/profile.d/00-container-environment.sh
    for i in $(env|cut -d '=' -f 1); do
        case $i in
            HOSTNAME|_|DEBIAN_FRONTEND|SHLVL|SKIP_OS_PKG_UPDATE|HOME|PWD|USER|LOGNAME|TERM|OLDPWD|SHELL)
                ;;
            *)
                printf "$i=" >>/etc/profile.d/00-container-environment.sh
                echo "${!i}" |sed 's/\(.\)/\\\1/g' \
                    >>/etc/profile.d/00-container-environment.sh
                ;;
        esac
    done
    echo "set +a" >>/etc/profile.d/00-container-environment.sh
}

# Nimbix JARVICE emulation
function setup_jarvice_emulation {
    cd /tmp
    curl https://codeload.github.com/nimbix/image-common/zip/$BRANCH \
        >/tmp/nimbix.zip
    unzip nimbix.zip
    rm -f nimbix.zip
    /tmp/image-common-$BRANCH/setup-nimbix.sh

    mkdir -p /usr/lib/JARVICE
    cp -a /tmp/image-common-$BRANCH/tools /usr/lib/JARVICE
    mkdir -p /usr/local/JARVICE
    cp -a /tmp/image-common-$BRANCH/tools /usr/local/JARVICE
    cat <<'EOF' | tee /etc/profile.d/jarvice-tools.sh >/dev/null
JARVICE_TOOLS="/usr/local/JARVICE/tools"
JARVICE_TOOLS_BIN="$JARVICE_TOOLS/bin"
PATH="$PATH:$JARVICE_TOOLS_BIN"
export JARVICE_TOOLS JARVICE_TOOLS_BIN PATH
EOF

    cd /tmp
    mkdir -p /etc/JARVICE
    cp -a /tmp/image-common-$BRANCH/etc/* /etc/JARVICE
    chmod 755 /etc/JARVICE
    mkdir -m 0755 -p /data
    chown nimbix:nimbix /data
}

function setup_nimbix_desktop() {
    mkdir -p /usr/local/lib/nimbix_desktop
    if [ -f /etc/redhat-release ]; then
        files="install-centos-tiger.sh"
        files+=" install-centos-real.sh help-real.html postinstall-real.sh"
    else
        files="install-ubuntu-tiger.sh"
    fi
    files+=" help-tiger.html postinstall-tiger.sh"
#    files+=" nimbix_desktop url.txt xfce4-session-logout share skel.config"
    files+=" nimbix_desktop url.txt xfce4-session-logout share"
    for i in $files; do
        cp -a /tmp/image-common-$BRANCH/nimbix_desktop/$i \
            /usr/local/lib/nimbix_desktop
    done
    if [ -f /etc/redhat-release ]; then
        if [ -n "$SETUP_REALVNC" ]; then
            /usr/local/lib/nimbix_desktop/install-centos-real.sh
        else
            /usr/local/lib/nimbix_desktop/install-centos-tiger.sh
        fi
        yum clean all
        #echo "/usr/local/bin/nimbix_desktop" >>/etc/rc.local
    else
        /usr/local/lib/nimbix_desktop/install-ubuntu-tiger.sh
    fi

    rm -f /usr/lib/JARVICE/tools/nimbix_desktop
    ln -sf /usr/local/lib/nimbix_desktop/ /usr/lib/JARVICE/tools/nimbix_desktop

    # recreate nimbix user home to get the right skeleton files
    /bin/rm -rf /home/nimbix
    /sbin/mkhomedir_helper nimbix

    # Add a marker file for using a local, updated noVNC install
    echo /usr/local/JARVICE/tools/noVNC | sudo tee /etc/.novnc-stable
}

#function setup_post() {
#    toolsdir=/usr/lib/JARVICE/tools
#    [ -d /usr/local/JARVICE/tools ] && toolsdir=/usr/local/JARVICE/tools
#    /bin/true
#}

function cleanup() {
    if [ -f /etc/redhat-release ]; then
        yum clean all
    else # Ubuntu
        apt-get clean
    fi
    rm -rf /tmp/image-common-$BRANCH
}

setup_base_os
setup_jarvice_emulation
[ -n "$SETUP_NIMBIX_DESKTOP" ] && setup_nimbix_desktop
#setup_post
cleanup

exit 0
