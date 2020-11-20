#!/bin/bash -ex

# Install RealVNC service but park in alternate location, , leaving Tiger as
#   default, enable switching

INSTALLPATH=/usr/local/realvnc
CONFIGPATH=/etc/vnc
SHAREPATH=/usr/share/vnc
LIBPATH=/usr/lib/vnc

# update links
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"

# Download the tarball of RPMs and un-archive to retrieve the RPMs
wget --content-disposition -O - "$REALVNC"|tar -C /tmp -xzf -

# create the paths required by alternatives
mkdir $CONFIGPATH
mkdir $SHAREPATH
mkdir $INSTALLPATH
mkdir $LIBPATH

# XXX For licensing to work: install defaults (hard coding fails at work), then
#     save config, remove RPM and restore config, then add alternate install
rpm -Uvh /tmp/VNC-Server-*-Linux-x64.rpm
tar czvf /tmp/realvnc-cfg.tgz /etc/vnc
rpm -e realvnc-vnc-server
cd / && tar xf /tmp/realvnc-cfg.tgz

# Now install in alternate location
export PATH=/usr/local/realvnc/bin:$PATH
rpm -Uvh --prefix=$INSTALLPATH /tmp/VNC-Server-*-Linux-x64.rpm
rm -f /tmp/VNC-*.rpm /tmp/realvnc-cfg.tgz

# Install the alternatives link for vncserver, Xvnc, etc.
alternatives --verbose --install /usr/bin/vncserver vncserver /usr/local/realvnc/bin/vncserver-virtual 10 \
             --slave /usr/bin/Xvnc Xvnc /usr/local/realvnc/bin/Xvnc-realvnc \
             --slave /usr/bin/Xvnc-core Xvnc-core /usr/local/realvnc/bin/Xvnc-realvnc-core \
             --slave /usr/bin/vnclicense vnclicense /usr/local/realvnc/bin/vnclicense \
             --slave /usr/bin/vnclicensehelper vnclicensehelper /usr/local/realvnc/bin/vnclicensehelper \
             --slave /usr/bin/vncinitconfig vncinitconfig /usr/local/realvnc/bin/vncinitconfig \
             --slave /usr/lib/vnc/get_primary_ip4 get_primary_ip4 /usr/local/realvnc/lib/vnc/get_primary_ip4 \
             --slave /usr/lib/vnc/vncelevate vncelevate /usr/local/realvnc/lib/vnc/vncelevate \
             --slave /usr/bin/vncserverui vncserverui /usr/local/realvnc/bin/vncserverui \
             --slave /usr/share/vnc/rgb.txt rgb.txt /usr/local/realvnc/share/vnc/rgb.txt

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=$(pwd)
mkdir -p /etc/NAE
#cp "$dirname"/help-real.html /etc/NAE/help.html
cp "$dirname"/help-real.html /etc/NAE/
