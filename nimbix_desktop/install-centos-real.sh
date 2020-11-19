#!/bin/bash -ex

INSTALLPATH=/usr/local/realvnc
CONFIGPATH=/etc/vnc
SHAREPATH=/usr/share/vnc

# update links
#REALVNC_VER=6.2.1
#REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-Server-$REALVNC_VER-Linux-x64.rpm"
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"

# Download the tarball of RPMs and un-archive to retrieve the RPMs
wget --content-disposition -O - "$REALVNC"|tar -C /tmp -xzf -

# Install to alternate location, leaving Tiger as default, and not conflicting
#   by files
mkdir $CONFIGPATH
mkdir $SHAREPATH
mkdir $INSTALLPATH
rpm -Uvh --prefix=$INSTALLPATH /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm
#  XXX ln -sf /usr/bin/Xvnc-realvnc /usr/bin/Xvnc

# Install the alternatives link for vncserver and Xvnc
#sudo alternatives --install /usr/bin/vncserver vncserver /usr/local/realvnc/bin/vncserver-virtual 10
#                  --slave /usr/bin/Xvnc Xvnc /usr/local/realvnc/bin/Xvnc-realvnc
alternatives --verbose --install /usr/bin/vncserver vncserver /usr/local/realvnc/bin/vncserver-virtual 10 \
             --slave /usr/bin/Xvnc Xvnc /usr/local/realvnc/bin/Xvnc-realvnc \
             --slave /usr/bin/vnclicense vnclicense /usr/local/realvnc/bin/vnclicense \
             --slave /usr/bin/vncserverui vncserverui /usr/local/realvnc/bin/vncserverui \
             --slave /usr/share/vnc/rgb.txt rgb.txt /usr/local/realvnc/share/vnc/rgb.txt

# TODO: find any effect of this error seen at install
#Updating / installing...
#realvnc-vnc-server-5.3.2.19179-1      ##
#[91m/var/tmp/rpm-tmp.D6xkSg: line 318: /usr/lib/vnc/rpmConflictSymlinks: No such file or directory
#[0mChecking for getenforce... [Not found]
#[91m/var/tmp/rpm-tmp.D6xkSg: line 338: vncinitconfig: command not found

#Couldn't open RGB_DB '/usr/share/vnc/rgb'

# link used to start up the service, virtual mode
#lrwxrwxrwx 1 root root        17 Sep 16 20:03 vncserver -> vncserver-virtual

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=$(pwd)
mkdir -p /etc/NAE
#cp "$dirname"/help-real.html /etc/NAE/help.html
cp "$dirname"/help-real.html /etc/NAE/
