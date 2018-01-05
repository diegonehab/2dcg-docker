FROM ubuntu:16.04

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN \
	echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu xenial main" >> /etc/apt/sources.list && \
	echo "deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu xenial main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA9EF27F && \
    apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y vim wget sudo && \
    adduser vg --gecos "" --disabled-password && \
    adduser vg sudo && \
    echo vg:vg | chpasswd

RUN \
    apt-get update && \
    apt-get install -y gcc-5 g++-5 && \
    apt-get install -y make && \
    apt-get install -y pkg-config

RUN \
    apt-get update && \
    apt-get install -y libboost-dev && \
    apt-get install -y libb64-dev && \
    apt-get install -y zlib1g-dev && \
    apt-get install -y libreadline-dev && \
    apt-get install -y libfreetype6-dev && \
    apt-get install -y libicu-dev && \
    apt-get install -y libharfbuzz-dev && \
    apt-get install -y libcairo2-dev

ADD b64.pc /usr/lib/x86_64-linux-gnu/pkgconfig
ADD lua53.pc /usr/lib/x86_64-linux-gnu/pkgconfig

ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig

# build and install latest version of Lua
RUN \
    wget https://www.lua.org/ftp/lua-5.3.4.tar.gz && \
    tar -zxvf lua-5.3.4.tar.gz && \
    rm -f lua-5.3.4.tar.gz && \
    cd lua-5.3.4 && \
    make linux && \
    make install && \
    cd .. && \
    rm -rf lua-5.3.4

# build and install libpng16 separately since it conflicts
# with libpng12 used by ubuntu
RUN \
    wget ftp://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.gz && \
    tar -zxvf libpng-1.6.34.tar.gz && \
    rm -f libpng-1.6.34.tar.gz && \
    cd libpng-1.6.34 && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf libpng-1.6.34

RUN \
    chown -R vg:vg /home/vg

USER vg

WORKDIR /home/vg

CMD ["/bin/bash", "-l"]
