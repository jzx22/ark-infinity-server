FROM ubuntu:18.04
LABEL maintainer="jzx222@gmail.com"

# Vars for first config
# Tag on github for ark server tools
ENV GIT_TAG v1.6.53
# Server PORT (you can't remap with docker, it doesn't work)
ENV SERVERPORT 27015
# Steam port (you can't remap with docker, it doesn't work)
ENV STEAMPORT 7778
# UID of the user steam
ENV UID 1000
# GID of the user steam
ENV GID 1000

# Install ark-server-tools dependencies
RUN apt-get update &&\
    apt-get install -y \
    apt-utils \
    perl-modules \
    curl \
    git \
    lsof \
    libc6-i386 \
    lib32gcc1 \
    bzip2 \
    >=bash-4.0 \
    >=coreutils-7.6 \
    findutils \
    perl \
    rsync \
    sed \
    tar

# Run commands as the steam user
RUN adduser \
	--disabled-login \
	--shell /bin/bash \
	--gecos "" \
	steam

# Add to sudo group
RUN usermod -a -G sudo steam

# Copy & rights to folders
COPY crontab /home/steam/crontab
COPY arkmanager.cfg /home/steam/arkmanager.cfg
RUN touch /root/.bash_profile

# We use the git method, because api github has a limit ;)
RUN  git clone https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools
WORKDIR /home/steam/ark-server-tools/
RUN  git checkout $GIT_TAG

# Install arkmanager
WORKDIR /home/steam/ark-server-tools/tools
RUN chmod +x install.sh
RUN ./install.sh steam --install-service

# Allow crontab to call arkmanager
RUN ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

# Define default config file in /etc/arkmanager
COPY arkmanager.cfg /etc/arkmanager/arkmanager.cfg

# Define default instance config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

#Steam dependency setup
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lib32stdc++6 \
    software-properties-common
RUN add-apt-repository multiverse
RUN apt update
RUN dpkg --add-architecture i386
RUN apt-get update -y
RUN apt-get install -y lib32gcc1

#Agree to steamcmd licence beforehand and install
RUN echo steam steam/question select "I AGREE" | debconf-set-selections
RUN echo steam steam/license note '' | debconf-set-selections
#RUN apt-get install -y steamcmd
RUN apt-get install -y --no-install-recommends ca-certificates locales steamcmd

# Create symlink for steamcmd
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

#Switch to steam user
USER steam

# First run is on anonymous to download the app
WORKDIR /usr/games/
RUN steamcmd +login anonymous +quit

#Install the server
#RUN arkmanager install
RUN arkmanager upgrade-tools

#Expose ports
EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

VOLUME  /home/steam/ARK

# Change the working directory to /ark
WORKDIR /home/steam/ARK

# Start the server
#ENTRYPOINT ["arkmanager", "start", "@all"]
ENTRYPOINT ["arkmanager", "install"]
