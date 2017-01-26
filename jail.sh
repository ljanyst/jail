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
JAIL_TYPE=container
LOG_DIR=$HOME_DIR/logs
CONFIG=$HOME_DIR/jail.cfg
CONT_HOSTNAME=jail
CONT_HOME=$HOME/Contained/jail/home
CONT_NAME=jail:v01
CONT_DEVICES=
CONT_USB=
CONT_PULSE_ACL=172.17.0.0/16
CONT_RESOLUTION=1024x768
CONT_IP=0.0.0.0

USER_NAME=prisoner
USER_COMMAND=startxfce4

if [ $# -eq 1 ]; then
  CONFIG=$HOME_DIR/${1}.cfg
fi

#-------------------------------------------------------------------------------
# Import settings from a file and build initial arguments
#-------------------------------------------------------------------------------
if [ -r $CONFIG ]; then
  . $CONFIG
fi

CONT_ARGS="           -v /etc/localtime:/etc/localtime"
CONT_ARGS="$CONT_ARGS -v $CONT_HOME:/home"
CONT_ARGS="$CONT_ARGS -h $CONT_HOSTNAME"

if [ x"$CONT_NET" != x ]; then
  CONT_ARGS="$CONT_ARGS --net $CONT_NET --ip $CONT_IP"
fi

USER_ARGS=

if [ x$JAIL_TYPE == x"user" ]; then
  FUNC_SETUP=setUpUser
  FUNC_JAIL=runUser
  FUNC_INFO=infoUser
else
  FUNC_SETUP=setUpContainer
  FUNC_JAIL=runContainer
  FUNC_INFO=infoContainer
fi

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

function runNE()
{
  eval $@
  if [ $? -ne 0 ]; then
    echo "FAILED"
  else
    echo "OK"
  fi
}

#-------------------------------------------------------------------------------
# Check the software
#-------------------------------------------------------------------------------
STAMP=`date +%Y%m%d-%H%M%S`
echo "[i] Running jail: $STAMP"
echo "[i] Config: $CONFIG"
echo "[i] Jail type: $JAIL_TYPE"
function infoContainer()
{
  echo "[i] Container: $CONT_NAME"
  echo "[i] Hostname: $CONT_HOSTNAME"
  echo "[i] Home: $CONT_HOME"
  if [ x"$CONT_NET" != x ]; then
    echo "[i] Network: $CONT_NET"
    echo "[i] IP Address: $CONT_IP"
  fi
}

function infoUser()
{
  echo "[i] User name: $USER_NAME"
  echo "[i] User command: $USER_COMMAND"
}

$FUNC_INFO

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
# Set up the container
#-------------------------------------------------------------------------------
function setUpContainer()
{
  #-----------------------------------------------------------------------------
  # Check if the container home exists
  #-----------------------------------------------------------------------------
  if [ ! -x $CONT_HOME/prisoner ]; then
    echo -n "[i] Creating the home dir: ${CONT_HOME}/prisoner... "
    run mkdir -p $CONT_HOME/prisoner
  fi

  #-----------------------------------------------------------------------------
  # Set up PulseAudio
  #-----------------------------------------------------------------------------
  if [ x"$CONT_PULSE_SERVER" == x ]; then
    IFCFG=`/sbin/ifconfig | grep 172.17`
    CONT_PULSE_SERVER=`echo $IFCFG | awk '{print $2}' | grep 172.17`
  fi

  if [ x"$CONT_PULSE_SERVER" == x ]; then
    echo "[!] Unable to auto-detect the PulseAudio server."
    exit 1
  fi

  echo -n "[i] Setting up the local PulseAudio server ($CONT_PULSE_SERVER)... "
  run "pactl load-module module-native-protocol-tcp auth-ip-acl=$CONT_PULSE_ACL > /dev/null 2>/dev/null"
  CONT_ARGS="$CONT_ARGS -e PULSE_SERVER=$CONT_PULSE_SERVER"

  #-----------------------------------------------------------------------------
  # Attach the devices
  #-----------------------------------------------------------------------------
  for DEV in $CONT_DEVICES; do
    if [ ! -e $DEV ]; then
      echo "[!] Device $DEV not present"
      continue
    fi
    echo "[i] Attaching device $DEV"
    CONT_ARGS="$CONT_ARGS --device=$DEV"
  done

  #-----------------------------------------------------------------------------
  # Attach USB devices
  #-----------------------------------------------------------------------------
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
}

#-------------------------------------------------------------------------------
# Set up the user jail
#-------------------------------------------------------------------------------
function setUpUser()
{
  getent passwd $USER_NAME >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "[!] User account $USER_NAME does not exist"
    exit 1
  fi

  for PROG in sudo $USER_COMMAND; do
    if test x`findProg $PROG` = x; then
      echo "[!] Unable to find $PROG. Bye!"
      exit 1
    fi
  done

  USER_ARGS="sudo -u $USER_NAME $USER_COMMAND"
}

$FUNC_SETUP

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
run "kill -0 $PID_XEPHYR > /dev/null 2> /dev/null"

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
      xsel -o -b --display $1 | xsel -i -b --display $2
      CLIP1=$CLIP1NEW
    fi;
    if [ x"$CLIP2" != x"$CLIP2NEW" ]; then
      xsel -o -b --display $2 | xsel -i -b --display $1
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
function runContainer()
{
  echo -n "[i] Running docker... "
  runNE "docker run -it $CONT_ARGS $CONT_NAME > $LOG_OUT 2> $LOG_ERR"

  CONT_IDS="`docker ps -a | grep $CONT_NAME | grep -v Up | awk '{print $1}'`"
  for CONT_ID in $CONT_IDS; do
    echo -n "[i] Removing container $CONT_ID... "
    runNE "docker rm $CONT_ID >/dev/null"
  done
}

#-------------------------------------------------------------------------------
# Run user
#-------------------------------------------------------------------------------
function runUser()
{
  echo -n "[i] Running sudo... "
  runNE "DISPLAY=:$JAIL_DISPLAY $USER_ARGS > $LOG_OUT 2> $LOG_ERR"

  echo -n "[i] Killing all the processes of $USER_NAME... "
  KILL_PROGS="ps aux | awk '{print \$1 \" \" \$2}' | grep $USER_NAME |"
  KILL_PROGS="$KILL_PROGS awk '{print \$2}' | sudo -u $USER_NAME xargs kill -9"
  KILL_PROGS="$KILL_PROGS && true"
  run $KILL_PROGS
}

$FUNC_JAIL

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
echo "OK"

exec 2>&3          # restore stderr to saved
exec 3>&-          # close saved version

echo -n "[i] Killing Xephyr, PID: $PID_XEPHYR... "
kill $PID_XEPHYR > /dev/null 2>/dev/null
wait $PID_XEPHYR
echo "OK"

echo "[i] All done. Bye!"
