:

#rm -rf /etc/skel/{.config,.local}
#mkdir -p /etc/skel/.config
#cp -r $dirname/skel.config/xfce4 /etc/skel/.config
#chmod -R u+w /etc/skel/.config/xfce4

#SKEL_CONFIGS=$(cd $dirname/skel.config && find . -type f)
#for i in $SKEL_CONFIGS; do
#    mkdir -p $(dirname /etc/skel/.config/$i)
#    cp -f $dirname/skel.config/$i /etc/skel/.config/$i
#    chmod u+w /etc/skel/.config/$i
#done

rm -f /usr/local/bin/nimbix_desktop
ln -sf $dirname/nimbix_desktop /usr/local/bin/nimbix_desktop
rm -f /usr/local/bin/xfce4-session-logout
ln -sf $dirname/xfce4-session-logout /usr/local/bin/xfce4-session-logout

mkdir -p /etc/NAE

if [ -z "$DISABLE_DESKTOP_AUTOSTART" ]; then
    if [ ! -e /etc/NAE/url.txt ]; then
        echo 'https://%PUBLICADDR%/vnc.html?password=%NIMBIXPASSWD%&autoconnect=true&reconnect=true' >/etc/NAE/url.txt
    fi
fi

if [ -d /etc/init.d ]; then
    required_start='networking'
    [ -f /etc/redhat-release ] && required_start='$network'
    cat >/etc/init.d/nimbix_desktop <<EOF
#!/bin/sh -e
# chkconfig: 345 99 00

### BEGIN INIT INFO
# Provides:          nimbix_desktop
# Required-Start:    $required_start
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
### END INIT INFO

if [ -f /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions

    case "\$1" in
        start)
            echo "Starting nimbix_desktop..."
            start_daemon /usr/local/bin/nimbix_desktop
            ;;
        stop)
            echo "Stopping nimbix_desktop not implemented..."
            ;;
    esac
elif [ -f /etc/init.d/functions ]; then
    . /etc/init.d/functions

    case "\$1" in
        start)
            echo "Starting nimbix_desktop..."
            /usr/local/bin/nimbix_desktop && success || failure
            ;;
        stop)
            echo "Stopping nimbix_desktop not implemented..."
            ;;
    esac
fi

exit 0
EOF
    chmod 755 /etc/init.d/nimbix_desktop
fi

if [ -d /etc/systemd/system ]; then
    cat >/etc/systemd/system/nimbix_desktop.service <<EOF
[Unit]
Description=Nimbix Desktop
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nimbix_desktop
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

if [ -z "$DISABLE_DESKTOP_AUTOSTART" ]; then
    (type -p systemctl && systemctl enable nimbix_desktop) || \
    (type -p update-rc.d && update-rc.d nimbix_desktop defaults) || \
    (type -p chkconfig && chkconfig --add nimbix_desktop) || \
    /bin/true
fi
