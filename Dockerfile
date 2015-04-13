FROM phusion/baseimage:0.9.16

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ENV TERM xterm
ENV PYTHON /usr/bin/python2.7

RUN apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:fkrull/deadsnakes \
    && add-apt-repository -y "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.5-binaries main" \
    && add-apt-repository -y ppa:ethereum/ethereum-qt \
    && add-apt-repository -y ppa:ethereum/ethereum \
    && add-apt-repository -y ppa:ethereum/ethereum-dev \
    && curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash - \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y nodejs git build-essential nano python2.7 redis-server solc

ADD ./ /src/

RUN cd /src \
    && npm install 

RUN mkdir -p /etc/service/seusscoin \
    && cp /src/config/run.sh /etc/service/seusscoin/run 

