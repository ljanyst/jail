
Jail
====

**Jail** is a helper script that I use to sandbox GUI applications using
*Docker*. It starts a *Xephyr* instance to separate the apps from the host X
server, synchronizes the clipboards, forwards sound to the host *PulseAudio*
server, and handles the devices that the container needs. The result should look
much like this:

![Jail](https://raw.githubusercontent.com/ljanyst/jail/master/screenshot.png)

Have a look here for more details: [http://jany.st/post/2016-11-22-containing-gui-application-with-docker.html](http://jany.st/post/2016-11-22-containing-gui-application-with-docker.html)

Usage
-----

**Jail** should be installed in *~/Apps/jail*. If you don't like that, you can
adjust the location by editing the `HOME_DIR` variable in the script.

Container Jail
--------------

You need to build the *Docker* image before you can do anything else. Go to the
*docker* subdir and type:

    docker build -t jail:v01 .

You can adjust the *Docker* tag and other things in the *jail.cfg* configuration
file. After the docker image is ready, you can run *jail.sh*:

    ]==> jail.sh
    [i] Running jail: 20161213-131751
    [i] Config: /home/ljanyst/Apps/jail/jail.cfg
    [i] Jail type: container
    [i] Container: jail:v01
    [i] Hostname: jail
    [i] Home: /home/ljanyst/Contained/jail/home
    [i] Setting up the local PulseAudio server (172.17.42.1)... OK
    [i] Attaching device /dev/video0
    [i] USB device 21a9:1006 not present
    [i] Running Xephyr display at :1 (1680x1050)... OK
    [i] Running docker... OK
    [i] Removing container b41637c54e0f... OK
    [i] Killing clipboard forwarder, PID: 15725... OK
    [i] Killing Xephyr, PID: 15717... OK
    [i] All done. Bye!

User Jail
---------

You need to set up a user account and give yourself the sudo power to run
commands as tath user withough password. To add user account type:

    ]==> sudo useradd -m prisoner

Then, make sure your `/etc/sudoers` file has a line like this in it:

    myself ALL=(prisoner) NOPASSWD: ALL

It means that user `myself` can run all possible commands as user `prisoner`
without being prompted for a password. If everything goes well you should
see something like this:

    ]==> jail.sh jail-user
    [i] Running jail: 20161213-132113
    [i] Config: /home/ljanyst/Apps/jail/jail-user.cfg
    [i] Jail type: user
    [i] User name: prisoner
    [i] User command: startxfce4
    [i] Running Xephyr display at :1 (1680x1050)... OK
    [i] Running sudo... OK
    [i] Killing all the processes of prisoner... OK
    [i] Killing clipboard forwarder, PID: 17365... OK
    [i] Killing Xephyr, PID: 17357... OK
    [i] All done. Bye!
