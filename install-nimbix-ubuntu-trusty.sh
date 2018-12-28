#!/bin/bash

set -e
set -x
export DEBIAN_FRONTEND=noninteractive
"$(dirname $0)/setup-nimbix.sh"
touch /etc/init.d/systemd-logind && apt-get update && apt-get -y install module-init-tools xz-utils vim openssh-server libpam-systemd libmlx4-1 libmlx5-1 iptables infiniband-diags build-essential curl libibverbs-dev libibverbs1 librdmacm1 librdmacm-dev rdmacm-utils libibmad-dev libibmad5 byacc flex git cmake screen grep && apt-get clean && locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
mkdir -p /usr/lib/JARVICE && cp -a "$(dirname $0)/tools" /usr/lib/JARVICE
cp -a "$(dirname $0)/etc" /etc/JARVICE && chmod 0755 /etc/JARVICE
mkdir -m 0755 /data && chown ${JARVICE_ID_USER}:${JARVICE_ID_USER} /data
[ -f /etc/init/ssh.conf ] && sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf

echo "set -a" >/etc/profile.d/00-container-environment.sh && env |grep -v ^HOSTNAME=|grep -v ^PWD=|grep -v ^DEBIAN_FRONTEND=|grep -v ^HOME=|grep -v ^SHLVL= >>/etc/profile.d/00-container-environment.sh && echo "set +a" >>/etc/profile.d/00-container-environment.sh
