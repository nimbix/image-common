:
rm -rf /etc/skel/{.config,.local}
mkdir -p /etc/skel/.config
cp -r $dirname/skel.config/xfce4 /etc/skel/.config
chmod -R u+w /etc/skel/.config/xfce4
rm -f /usr/local/bin/nimbix_desktop
ln -s $dirname/nimbix_desktop /usr/local/bin/nimbix_desktop
rm -f /usr/local/bin/xfce4-session-logout
ln -s $dirname/xfce4-session-logout /usr/local/bin/xfce4-session-logout

mkdir -p /etc/NAE
cp $dirname/help-tiger.html /etc/NAE/help.html
echo 'https://%PUBLICADDR%/vnc.html?password=%NIMBIXPASSWD%' >/etc/NAE/url.txt

