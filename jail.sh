#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (c) 2016 by Lukasz Janyst <lukasz@jany.st>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
HOME_DIR=$HOME/Apps/jail
LOG_DIR=$HOME_DIR/logs
CONT_HOSTNAME=jail
CONT_HOME=$HOME/Contained/jail/home
CONT_NAME=jail:v07
CONT_DEVICES=
CONT_USB=
CONT_PULSE_SERVER=172.17.0.1
CONT_PULSE_CLIENT=172.17.0.2
CONT_RESOLUTION=1024x768

#-------------------------------------------------------------------------------
# Import settings from a file and build initial arguments
#-------------------------------------------------------------------------------
if [ -r $HOME_DIR/jail.cfg ]; then
  . $HOME_DIR/jail.cfg
fi

CONT_ARGS="           -v /etc/localtime:/etc/localtime"
CONT_ARGS="$CONT_ARGS -v $CONT_HOME:/home"
CONT_ARGS="$CONT_ARGS -h $CONT_HOSTNAME"

#-------------------------------------------------------------------------------
# Utilities
#-------------------------------------------------------------------------------
function findProg()
{
  for PROG in $@; do
    if [ -x "`which $PROG 2>/dev/null`" ]; then
      echo $PROG
      break
    fi
  done
}

function run()
{
  eval $@
  if [ $? -ne 0 ]; then
    echo "FAILED"
    exit 1
  fi
  echo "OK"
}

#-------------------------------------------------------------------------------
# Check the software
#-------------------------------------------------------------------------------
STAMP=`date +%Y%m%d-%H%M%S`
echo "[i] Running jail: $STAMP"
echo "[i] Container: $CONT_NAME"
echo "[i] Hostname: $CONT_HOSTNAME"
echo "[i] Home: $CONT_HOME"

for PROG in Xephyr docker xsel pactl lsusb awk; do
  if test x`findProg $PROG` = x; then
    echo "[!] Unable to find $PROG. Bye!"
    exit 1
  fi
done

#-------------------------------------------------------------------------------
# Set up the log files for the container
#-------------------------------------------------------------------------------
if [ ! -x $LOG_DIR ]; then
  echo -n "[i] Creating a log dir: $LOG_DIR... "
  run mkdir -p $LOG_DIR
fi

if [ ! -w $LOG_DIR ]; then
    echo "[!] Log dir is not writable."
    exit 1
fi

for LOG in out err; do
  LOG_FILE=$LOG_DIR/jail-log-$STAMP.$LOG
  if [ -x $LOG_FILE -a ! -w $LOG_FILE ]; then
    echo "[!] Log file $LOG_FILE is not writable."
    exit 1
  fi
done

LOG_OUT=$LOG_DIR/jail-log-$STAMP.$LOG
LOG_ERR=$LOG_DIR/jail-log-$STAMP.$LOG

#-------------------------------------------------------------------------------
# Check if the container home exists
#-------------------------------------------------------------------------------
if [ ! -x $CONT_HOME/prisoner ]; then
  echo -n "[i] Creating the home dir: ${CONT_HOME}/prisoner... "
  run mkdir -p $CONT_HOME/prisoner
fi

#-------------------------------------------------------------------------------
# Set up pulse audio
#-------------------------------------------------------------------------------
echo -n "[i] Setting up the local PulseAudio server... "
run "pactl load-module module-native-protocol-tcp auth-ip-acl=$CONT_PULSE_CLIENT > /dev/null 2>/dev/null"
CONT_ARGS="$CONT_ARGS -e PULSE_SERVER=$CONT_PULSE_SERVER"

#-------------------------------------------------------------------------------
# Attach the devices
#-------------------------------------------------------------------------------
for DEV in $CONT_DEVICES; do
  if [ ! -e $DEV ]; then
    echo "[!] Device $DEV not present"
    continue
  fi
  echo "[i] Attaching device $DEV"
  CONT_ARGS="$CONT_ARGS --device=$DEV"
done

#-------------------------------------------------------------------------------
# Attach USB devices
#-------------------------------------------------------------------------------
for DEVID in $CONT_USB; do
  DEVSTR=`lsusb -d $DEVID`
  if [ $? -ne 0 ]; then
    echo "[i] USB device $DEVID not present"
    continue
  fi
  USBBUS=`echo $DEVSTR | awk '{print $2}'`
  USBDEV=`echo $DEVSTR | awk '{print $4}' | tr -d ':'`
  DEV=/dev/bus/usb/$USBBUS/$USBDEV
  echo "[i] Attaching USB device $DEVID as $DEV"
  CONT_ARGS="$CONT_ARGS --device=$DEV"
done

#-------------------------------------------------------------------------------
# Find a free display and run Xephyr
#-------------------------------------------------------------------------------
JAIL_DISPLAY=":0"
for i in `seq 9`; do
  if [ ! -x /tmp/.X11-unix/X$i ]; then
    JAIL_DISPLAY=$i
    break
  fi
done

echo -n "[i] Running Xephyr display at :$JAIL_DISPLAY ($CONT_RESOLUTION)... "
Xephyr :$JAIL_DISPLAY -ac -br -screen $CONT_RESOLUTION -resizeable > $LOG_OUT 2> $LOG_ERR &

# wait and see if the signal is deliverable to check whether it's alive
PID_XEPHYR=$!
sleep 1
kill -0 $PID_XEPHYR > /dev/null 2> /dev/null
if [ $? -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "OK"

# pass the display variable and forward the appropriate socket
CONT_ARGS="$CONT_ARGS -e DISPLAY=:$JAIL_DISPLAY"
CONT_ARGS="$CONT_ARGS -v /tmp/.X11-unix/X${JAIL_DISPLAY}:/tmp/.X11-unix/X${JAIL_DISPLAY}"

#-------------------------------------------------------------------------------
# Set up clipboard forwarding between displays
#-------------------------------------------------------------------------------
function clipForward()
{
  CLIP1=""
  CLIP2=`xsel -o -b --display $2`
  while true; do
    CLIP1NEW=`xsel -o -b --display $1`
    CLIP2NEW=`xsel -o -b --display $2`
    if [ "x$CLIP1" != "x$CLIP1NEW" ]; then
      echo $CLIP1NEW | xsel -i -b --display $2
      CLIP1=$CLIP1NEW
    fi;
    if [ x"$CLIP2" != x"$CLIP2NEW" ]; then
      echo $CLIP2NEW | xsel -i -b --display $1
      CLIP2=$CLIP2NEW
    fi
    sleep 1
  done
}

clipForward ":0" ":$JAIL_DISPLAY" &
PID_FORWARDER=$!

#-------------------------------------------------------------------------------
# Run docker
#-------------------------------------------------------------------------------
echo -n "[i] Running docker... "
eval "docker run -it $CONT_ARGS $CONT_NAME > $LOG_OUT 2> $LOG_ERR"
if [ $? -ne 0 ]; then
  echo "FAILED"
else
  echo "DONE"
fi

#-------------------------------------------------------------------------------
# The container is done, kill everyone
#-------------------------------------------------------------------------------

# do the stderr descriptor juggling to suppress bash message about terminated
# background job
exec 3>&2          # 3 is now a copy of 2
exec 2> /dev/null  # 2 now points to /dev/null

echo -n "[i] Killing clipboard forwarder, PID: $PID_FORWARDER... "
kill $PID_FORWARDER > /dev/null 2> /dev/null
wait $PID_FORWARDER
echo "DONE"

exec 2>&3          # restore stderr to saved
exec 3>&-          # close saved version

echo -n "[i] Killing Xephyr, PID: $PID_XEPHYR... "
kill $PID_XEPHYR > /dev/null 2>/dev/null
wait $PID_XEPHYR
echo "DONE"

echo "[i] All done. Bye!"
