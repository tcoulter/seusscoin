FROM phusion/baseimage:0.9.16

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

########### ORIGINAL CLIENT-GO DOCKERFILE ###########

## Environment setup
ENV HOME /root
ENV GOPATH /root/go
ENV PATH /root/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

RUN mkdir -p /root/go
ENV DEBIAN_FRONTEND noninteractive

## Install base dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git mercurial build-essential software-properties-common wget pkg-config libgmp3-dev libreadline6-dev libpcre3-dev libpcre++-dev

## Install Qt5.4.1 (not required for CLI)
# RUN add-apt-repository ppa:beineri/opt-qt541-trusty -y
# RUN apt-get update -y
# RUN apt-get install -y qt54quickcontrols qt54webengine mesa-common-dev libglu1-mesa-dev
# ENV PKG_CONFIG_PATH /opt/qt54/lib/pkgconfig

# Install Golang
RUN wget https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go*.tar.gz && go version

# this is a workaround, to make sure that docker's cache is invalidated whenever the git repo changes
ADD https://api.github.com/repos/ethereum/go-ethereum/git/refs/heads/develop file_does_not_exist

## Fetch and install go-ethereum
RUN mkdir -p $GOPATH/src/github.com/ethereum/
RUN git clone https://github.com/ethereum/go-ethereum $GOPATH/src/github.com/ethereum/go-ethereum
WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
RUN git checkout develop
RUN GOPATH=$GOPATH:$GOPATH/src/github.com/ethereum/go-ethereum/Godeps/_workspace go install -v ./cmd/geth

EXPOSE 8545

########### ORIGINAL CLIENT-GO DOCKERFILE ###########

ENV TERM xterm

# Create the init script for running geth.
# When the container is run, it expects an environment variable called $PASSWORD
# which will be used for the account password.

# WARNING: This is good for the test network, but not for the real network!
#          You have been warned!

RUN mkdir /etc/service/geth \
    && touch /etc/service/geth/run \
    && printf '#!/bin/bash\n' >> /etc/service/geth/run \
    && printf 'echo $PASSWORD > /passwordfile \n' >> /etc/service/geth/run \
    && printf 'geth --password=/passwordfile account new \n' >> /etc/service/geth/run \
    && printf "geth --password=/passwordfile --nodekeyhex='88b5b1e92c44067431181f8986600933f272c108ae2dd7ae98ba1fddbb1dca59' --mine --unlock=primary -rpc=true -rpcport=8545 --rpccorsdomain='*'  --rpcaddr=\"\`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'\`\" " >> /etc/service/geth/run \
    && chmod 755 /etc/service/geth/run

# Expose the p2p port.
EXPOSE 30303


