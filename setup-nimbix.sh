#!/bin/sh
/usr/sbin/groupadd -g 505 nimbix
/usr/sbin/useradd -u 505 -g 505 -m -s /bin/bash nimbix
cat <<EOF >/etc/sudoers.d/00-nimbix
Defaults: nimbix !requiretty
Defaults: root !requiretty
nimbix ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/00-nimbix
[ -d /etc/init ] && echo "manual" >/etc/init/network-manager.override

# for standalone use
/usr/sbin/usermod -p '$1$CJ/DkP.D$4N9cy3Y2AhrU7ekFCjW/n.' nimbix

