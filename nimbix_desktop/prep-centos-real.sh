#!/bin/bash

# update links
REALVNC="https://www.realvnc.com/download/file/vnc.files/VNC-5.3.2-Linux-x64-RPM.tar.gz"

# Download the tarball of RPMs and un-archive to retrieve the RPMs
wget --content-disposition -O - "$REALVNC"|tar -C /usr/local/lib/nimbix_desktop -xzf -
