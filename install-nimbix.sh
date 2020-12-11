#!/usr/bin/env bash

set -e
set -x

ARCH=$(arch)
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

# Base OS
function setup_base_os() {
    PKGS="curl zip unzip sudo"
    if [ -f /etc/redhat-release ]; then
        # install EPEL first, successive packages live there
        yum -y install epel-release

        # Packages to support MPI and basic container operation
        PKGS+=" passwd xz tar file openssh-server openssh-clients"
        PKGS+=" openmpi openmpi3 perftest which sshpass mailcap"
        PKGS+=" dapl compat-dapl dapl.i686 compat-dapl.i686 infiniband-diags"
        PKGS+=" rdma-core rdma-core.i686 libibverbs libibverbs-utils"
        [ -z "$SKIP_OS_PKG_UPDATE" ] && yum -y update
        yum -y install $PKGS

        # Set locale
        localedef -i en_US -f UTF-8 en_US.UTF-8

        echo '# leave empty' >/etc/fstab
    else # Ubuntu (assumed)

        touch /etc/init.d/systemd-logind

        export DEBIAN_FRONTEND=noninteractive
        PKGS+=" kmod xz-utils vim openssh-server libpam-systemd"
        PKGS+=" libmlx4-1 libmlx5-1 iptables infiniband-diags build-essential"
        PKGS+=" libibverbs-dev libibverbs1 librdmacm1 librdmacm-dev ibverbs-utils"
        PKGS+=" rdmacm-utils libibmad-dev libibmad5 byacc flex git cmake"
        PKGS+=" screen grep locales locales-all net-tools lsb-release"
        PKGS+=" openssh-client sshpass ca-certificates"

        # duplicated in VNC installers
#        if [ ! -e /usr/bin/python ]; then
#            PKGS+=" python python-pip"
#        fi

        # unfortunately on Ubuntu we can't skip the apt-get update since
        # most images have broken cache, so we have to do it anyway
        #(was [ -z "$SKIP_OS_PKG_UPDATE" ] && apt-get -y update)
        apt-get -y update
        # XXX ^^^
        apt-get -y install $PKGS

        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8

        # for versions past bionic, set the default python to py2 until py3 default works
        REL=$(lsb_release -r -s)
        MAJOR=${REL%\.*}
        if [[ $MAJOR -gt 18 ]]; then
          apt-get -y install python2 python3
          update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1
          update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2
        fi

        if [[ -f /etc/init/ssh.conf ]]; then
            sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf
        fi
    fi

}

# Nimbix JARVICE emulation
function setup_jarvice_emulation {
    cd /tmp
    curl https://codeload.github.com/nimbix/image-common/zip/$BRANCH \
        >/tmp/nimbix.zip
    unzip nimbix.zip
    rm -f nimbix.zip
    /tmp/image-common-$BRANCH/setup-nimbix.sh

    # Redundant directory copies, use a soft link, favor the /usr/local/ but
    #  J2 depends on this so allow the full copies for now
    mkdir -p /usr/lib/JARVICE
    cp -a /tmp/image-common-$BRANCH/tools /usr/lib/JARVICE
    mkdir -p /usr/local/JARVICE
    cp -a /tmp/image-common-$BRANCH/tools /usr/local/JARVICE
#    ln -sf /usr/local/JARVICE /usr/lib/JARVICE
    cat <<'EOF' | tee /etc/profile.d/jarvice-tools.sh >/dev/null
JARVICE_TOOLS="/usr/local/JARVICE/tools"
JARVICE_TOOLS_BIN="$JARVICE_TOOLS/bin"
PATH="$PATH:$JARVICE_TOOLS_BIN"
export JARVICE_TOOLS JARVICE_TOOLS_BIN PATH
EOF

    cd /tmp
    mkdir -p /etc/JARVICE
    cp -a /tmp/image-common-"$BRANCH"/etc/* /etc/JARVICE
    chmod 755 /etc/JARVICE
    mkdir -m 0755 /data
    chown nimbix:nimbix /data
}

function setup_nimbix_desktop() {
    mkdir -p /usr/local/lib/nimbix_desktop

    # Copy in the VNC server installers, both for CentOS, and the XFCE files
    if [ -f /etc/redhat-release ]; then
        files="install-centos-tiger.sh"
        files+=" install-centos-real.sh help-real.html"
    else
        files="install-ubuntu-tiger.sh"
    fi
    files+=" help-tiger.html postinstall-tiger.sh"
    files+=" nimbix_desktop url.txt xfce4-session-logout share skel.config"

    # Pull the files from the install bolus
    for i in $files; do
        cp -a /tmp/image-common-"$BRANCH"/nimbix_desktop/"$i" \
            /usr/local/lib/nimbix_desktop
    done

    # Install both VNC server types on CentOS, RealVNC only for x86_64 arch
    if [ -f /etc/redhat-release ]; then
        /usr/local/lib/nimbix_desktop/install-centos-tiger.sh
#        if [[ $ARCH == x86_64 && -n "$SETUP_REALVNC" ]]; then
        if [[ $ARCH == x86_64 ]]; then
          /usr/local/lib/nimbix_desktop/prep-centos-real.sh
        fi
    else
        /usr/local/lib/nimbix_desktop/install-ubuntu-tiger.sh
    fi

    # clean up older copies, make a link for all apps to find nimbix_desktop
    rm -f /usr/lib/JARVICE/tools/nimbix_desktop
    ln -sf /usr/local/lib/nimbix_desktop/ /usr/lib/JARVICE/tools/nimbix_desktop

    # recreate nimbix user home to get the right skeleton files
    /bin/rm -rf /home/nimbix
    /sbin/mkhomedir_helper nimbix

    # Add a marker file for using a local, updated noVNC install
    echo /usr/local/JARVICE/tools/noVNC | sudo tee /etc/.novnc-stable
}

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
cleanup

exit 0
