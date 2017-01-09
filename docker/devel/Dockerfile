
FROM debian:testing

#-------------------------------------------------------------------------------
# Update debian and install some base packages
#-------------------------------------------------------------------------------
COPY debian-extra.list /etc/apt/sources.list.d/debian-extra.list
RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install sudo xterm zsh git usbutils mc stow wget pciutils \
                       net-tools telnet apt-transport-https ca-certificates \
                       curl gnupg

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
# Scala
#-------------------------------------------------------------------------------
RUN echo "deb https://dl.bintray.com/sbt/debian /" > /etc/apt/sources.list.d/sbt.list && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
         --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    sudo apt-get -y update && \
    sudo apt-get -y install scala sbt

#-------------------------------------------------------------------------------
# Container setup
#-------------------------------------------------------------------------------
COPY runjail.sh /usr/bin/runjail.sh

RUN useradd -G sudo,video,plugdev -s /usr/bin/zsh prisoner

CMD /usr/bin/runjail.sh
