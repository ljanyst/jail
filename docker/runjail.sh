#!/bin/bash

set -e

echo "Pulse server is: $PULSE_SERVER"

# start dbus
mkdir /var/run/dbus
dbus-daemon --system --fork

# set up xfce
mkdir -p /home/prisoner/.config/xfce4
XINITRC=/home/prisoner/.config/xfce4/xinitrc
rm $XINITRC

echo -e "#!/bin/sh\n\n" >> $XINITRC
echo -e "export PULSE_SERVER=$PULSE_SERVER\n\n" >> $XINITRC
tail -n +2 /etc/xdg/xfce4/xinitrc >> $XINITRC

sudo -u prisoner startxfce4
