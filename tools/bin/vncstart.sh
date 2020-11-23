#!/usr/bin/env bash

. /etc/JARVICE/vglinfo.sh
if [ ! -x /usr/bin/vglrun ]; then
    export VGL_DISPLAY=""
fi

cd

rm -rf .vnc
mkdir -p .vnc
cat <<EOF >.vnc/xstartup
#!/bin/sh
if [ ! -z "$VGL_DISPLAY" ]; then
        VGL_DISPLAY=$VGL_DISPLAY; export VGL_DISPLAY
        VGL_READBACK=sync; export VGL_READBACK
        vglclient &
fi
xsetroot -solid "#000050"
xhost +
EOF
chmod +x .vnc/xstartup

if [ -d /etc/X11/fontpath.d ]; then
    FP="-fp catalogue:/etc/X11/fontpath.d,built-ins"
fi

# Start the VNC server
RET=1 && (vnclicense -check >/dev/null 2>&1) && RET=$?
if [[ -x /usr/bin/Xvnc-realvnc && -f /usr/lib/JARVICE/tools/etc/realvnc.key && $RET -eq 0 ]]; then
    echo "Enabling RealVNC server for VNC service"
    sudo cp -f /etc/NAE/help-real.html /etc/NAE/help.html
    mkdir -p ~/.vnc/config.d
    chmod 700 ~/.vnc/config.d
    cp -f /usr/lib/JARVICE/tools/etc/realvnc.key ~/.vnc/private.key
    chmod 600 ~/.vnc/private.key
    VNCPASSWD=$(cat /etc/JARVICE/vncpasswd-RealVNC)
    cat <<EOF >~/.vnc/config.d/Xvnc
Password=$VNCPASSWD
EOF
    touch ~/.vnc/config.d/.Xvnc-v5-marker
    /usr/bin/vncserver -geometry "$VNC_GEOMETRY" -StartUI=1 -EnableAutoUpdateChecks=0 \
        -ConnNotifyTimeout=0 \
        -AllowHttp=0 -Encryption PreferOn -Authentication VncAuth \
        -DisableAddNewClient -EnableRemotePrinting=0 -dpi 100 \
        -SecurityTypes RA2:256+,RA2,RA2ne,VeNCrypt,TLSVnc,VncAuth $FP :1
else
    # Default path to Tiger in /usr/local/bin
    /usr/local/bin/vncserver -geometry "$VNC_GEOMETRY" \
        -rfbauth /etc/JARVICE/vncpasswd \
        -dpi 100 \
        -SecurityTypes=VeNCrypt,TLSVnc,VncAuth :1
fi

export DISPLAY=:1
export LANG=en_US.UTF-8 # XXX
export TERM=xterm
export VGL_READBACK=sync

# Start noVNC daemon
NOVNC_PATH=/usr/local/JARVICE/tools/noVNC
pushd "$NOVNC_PATH"
(sudo utils/launch.sh --cert /etc/JARVICE/cert.pem --listen 443 --vnc localhost:5901 | sudo tee /tmp/novnc.log 2>&1 &)
echo "$NOVNC_PATH" | sudo tee /etc/.novnc-stable
popd

# Create links to the vault mounted at /data
ln -sf /data .
mkdir -p Desktop
ln -sf /data Desktop
sleep 2

if [ -z "$VGL_DISPLAY" ]; then
    exec "$@"
else
    exec vglrun -d $VGL_DISPLAY "$@"
fi
