#!/bin/bash

# Install the server RPM into default location
rpm -Uvh /usr/local/lib/nimbix_desktop/VNC-Server-*-Linux-x64.rpm
rm -f /usr/local/lib/nimbix_desktop/VNC-*.rpm

dirname=$(dirname $0)
[ "$dirname" = "." ] && dirname=$(pwd)
mkdir -p /etc/NAE

# replace help file
cp "$dirname"/help-real.html /etc/NAE/
