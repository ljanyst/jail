
FROM jail:base

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
