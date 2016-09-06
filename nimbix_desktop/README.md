This is the Nimbix Desktop.  It provides a XFCE 4 based desktop with default
configuration files.

To get started, simply execute install.sh to install the nimbix_desktop script,
XFCE packages, and default XFCE config files.  The default config provides a
Nimbix "N" icon at the left side of the bottom panel that provides a simple
start menu.

After installation, the desktop can be started by providing
/usr/local/bin/nimbix_desktop as the command given to "Visualize" a NAE.  A
default startup app can be given as an argument to nimbix_desktop (NAE
processing will complete upon app exit):
/usr/local/bin/nimbix_desktop /usr/bin/firefox

The following line can also be added to /etc/rc.local to start the desktop
on every boot of the NAE:
/usr/local/bin/nimbix_desktop

