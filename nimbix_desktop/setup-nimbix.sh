#!/bin/sh
/usr/sbin/groupadd -g ${JARVICE_ID_GID} ${JARVICE_ID_USER}
/usr/sbin/useradd -u ${JARVICE_ID_UID} -g ${JARVICE_ID_GID} -m -s /bin/bash \
        ${JARVICE_ID_USER}
cat <<EOF >/etc/sudoers.d/00-${JARVICE_ID_USER}
Defaults: ${JARVICE_ID_USER} !requiretty
Defaults: root !requiretty
${JARVICE_ID_USER} ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/00-${JARVICE_ID_USER}
chown ${JARVICE_ID_USER}:${JARVICE_ID_USER} /data
# recreate nimbix user home to get the right skeleton files
/bin/rm -rf /home/${JARVICE_ID_USER}
/sbin/mkhomedir_helper ${JARVICE_ID_USER}
[ -d /etc/init ] && echo "manual" >/etc/init/network-manager.override

# for standalone use
/usr/sbin/usermod -p '$1$CJ/DkP.D$4N9cy3Y2AhrU7ekFCjW/n.' ${JARVICE_ID_USER} 

