
FROM debian:testing

#-------------------------------------------------------------------------------
# Update debian and install some base packages
#-------------------------------------------------------------------------------
COPY debian-extra.list /etc/apt/sources.list.d/debian-extra.list
RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install sudo xterm zsh git usbutils mc stow wget pciutils \
                       net-tools telnet

#-------------------------------------------------------------------------------
# Install XFCE and some fonts
#-------------------------------------------------------------------------------
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get -y install xfce4 libgnome-keyring0 gnome-keyring xfce4-terminal \
                       python-gtk2 lsb-release libxslt1.1 ttf-bitstream-vera \
                       ttf-mscorefonts-installer fonts-roboto-hinted \
                       fonts-roboto fonts-oxygen fonts-hack-ttf fonts-dejavu \
                       fonts-dejavu-extra

#-------------------------------------------------------------------------------
# Iceweasel
#-------------------------------------------------------------------------------
RUN apt-get -y install iceweasel

#-------------------------------------------------------------------------------
# Google Chrome
#-------------------------------------------------------------------------------
RUN apt-get -y install apt-transport-https ca-certificates curl gnupg \
                       hicolor-icon-theme libgl1-mesa-dri libgl1-mesa-glx \
                       libpulse0 libv4l-0 fonts-symbola && \
    curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm /etc/apt/sources.list.d/google.list

#-------------------------------------------------------------------------------
# Skype
#-------------------------------------------------------------------------------
RUN cd /tmp && \
    wget https://go.skype.com/skypeforlinux-64-alpha.deb && \
    dpkg -i /tmp/skypeforlinux-64-alpha.deb

#-------------------------------------------------------------------------------
# Dropbox
#-------------------------------------------------------------------------------
RUN cd tmp && \
    wget "https://www.dropbox.com/download?dl=packages/debian/dropbox_2015.10.28_amd64.deb" -O dropbox_2015.10.28_amd64.deb && \
    dpkg -i dropbox_2015.10.28_amd64.deb

#-------------------------------------------------------------------------------
# Container setup
#-------------------------------------------------------------------------------
COPY runjail.sh /usr/bin/runjail.sh

RUN useradd -G sudo,video,plugdev -s /usr/bin/zsh prisoner

CMD /usr/bin/runjail.sh
