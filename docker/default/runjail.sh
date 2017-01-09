#!/bin/bash

set -e

echo "Pulse server is: $PULSE_SERVER"

# start dbus
mkdir /var/run/dbus
dbus-daemon --system --fork

# add the host's ip to /etc/hosts
echo -e "\n$PULSE_SERVER guard\n" >> /etc/hosts

# set up xfce
mkdir -p /home/prisoner/.config/xfce4
chown prisoner:prisoner -R /home/prisoner
XINITRC=/home/prisoner/.config/xfce4/xinitrc
rm -f $XINITRC

echo -e "#!/bin/sh\n\n" >> $XINITRC
echo -e "export PULSE_SERVER=$PULSE_SERVER\n\n" >> $XINITRC
tail -n +2 /etc/xdg/xfce4/xinitrc >> $XINITRC

sudo -u prisoner startxfce4
