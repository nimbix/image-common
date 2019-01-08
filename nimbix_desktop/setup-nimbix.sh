#!/bin/sh
# Assign default JARVICE user if not set
# username: nimbix 
# group: nimbix
# uid/gid: 505/505
JARVICE_ID_USER=${JARVICE_ID_USER:-nimbix}
JARVICE_ID_GROUP=${JARVICE_ID_GROUP:-nimbix}
JARVICE_ID_UID=${JARVICE_ID_UID:-505}
JARVICE_ID_GID=${JARVICE_ID_GID:-505}
# Create sudo file
mkdir -p /etc/sudoers.d
if [ -e /etc/sudoers.d/00-nimbix ]; then
    mv /etc/sudoers.d/00-nimbix /etc/sudoers.d/00-${JARVICE_ID_USER}
    sed -i "s/nimbix/${JARVICE_ID_USER}/g" /etc/sudoers.d/00-${JARVICE_ID_USER}
    # Attempt to remove default nimbix user
    /usr/sbin/userdel -r nimbix || true
else
    cat <<EOF >/etc/sudoers.d/00-${JARVICE_ID_USER}
Defaults: ${JARVICE_ID_USER} !requiretty
Defaults: root !requiretty
${JARVICE_ID_USER} ALL=(ALL) NOPASSWD: ALL
EOF
fi
chmod 0440 /etc/sudoers.d/00-${JARVICE_ID_USER}
# Create linux/unix user
/usr/sbin/groupadd -g ${JARVICE_ID_GID} ${JARVICE_ID_GROUP}
/usr/sbin/useradd -u ${JARVICE_ID_UID} -g ${JARVICE_ID_GID} -m -s /bin/bash \
        ${JARVICE_ID_USER}
# Setup mount point for JARVICE vault
chown ${JARVICE_ID_USER}:${JARVICE_ID_GROUP} /data
# recreate nimbix user home to get the right skeleton files
/bin/rm -rf /home/${JARVICE_ID_USER}
/sbin/mkhomedir_helper ${JARVICE_ID_USER}
[ -d /etc/init ] && echo "manual" >/etc/init/network-manager.override

# for standalone use
/usr/sbin/usermod -p '$1$CJ/DkP.D$4N9cy3Y2AhrU7ekFCjW/n.' ${JARVICE_ID_USER} 

