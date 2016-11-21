#!/bin/bash

set -e

mkdir /var/run/dbus
dbus-daemon --system --fork
sudo -u prisoner startxfce4
