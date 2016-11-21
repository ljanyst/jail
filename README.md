
Jail
====

**Jail** is a helper script that I use to sandbox GUI applications using
*Docker*. It starts a *Xephyr* instance to separate the apps from the host X
server, synchronizes the clipboards, forwards sound to the host *PulseAudio*
server, and handles the devices that the container needs. The result should look
much like this:

![Jail](https://raw.githubusercontent.com/ljanyst/jail/master/screenshot.png)

Usage
-----

**Jail** should be installed in *~/Apps/jail*. If you don't like that, you can
adjust the location by editing the `HOME_DIR` variable in the script. You need
to build the *Docker* image before you can do anything else, though. Go to the
*docker* subdir and type:

    docker build -t jail:v01 .

You can adjust the *Docker* tag and other things in the *jail.cfg* configuration
file. After the docker image is ready, you can run *jail.sh*:

    ]==> jail.sh
    [i] Running jail: 20161121-220351
    [i] Container: jail:v01
    [i] Hostname: jail
    [i] Home: /home/ljanyst/Contained/jail/home
    [i] Setting up the local PulseAudio server (172.17.42.1)... OK
    [i] Attaching device /dev/video0
    [i] USB device 21a9:1006 not present
    [i] Running Xephyr display at :1 (1680x1050)... OK
    [i] Running docker... OK
    [i] Removing container 6509664eb94f... OK
    [i] Killing clipboard forwarder, PID: 7878... DONE
    [i] Killing Xephyr, PID: 7870... DONE
    [i] All done. Bye!
