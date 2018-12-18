FROM ubuntu:18.04

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

# Install basic development tools
# ----------------------------------------------------
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        libb64-dev \
        libboost-dev \
        libboost-dev \
        libcairo2-dev \
        libfreetype6-dev \
        libharfbuzz-dev \
        libicu-dev \
        libpng-dev \
        libreadline-dev \
        pkg-config \
        socat \
        unzip \
        vim \
        wget \
        zlib1g-dev \
    && \
    rm -rf /var/lib/apt/lists/*

COPY b64.pc /usr/local/lib/pkgconfig/

# Install Lua 5.3.5 compiled for C++
# ----------------------------------------------------
COPY luapp.patch /root
COPY luapp53.pc /usr/local/lib/pkgconfig/

RUN \
    NPROC=$(nproc) && \
    cd /root && \
    wget https://www.lua.org/ftp/lua-5.3.5.tar.gz && \
    tar -zxvf lua-5.3.5.tar.gz && \
    cd /root/lua-5.3.5 && \
    patch -p1 < ../luapp.patch && \
    make -j$NPROC linux && \
    make install && \
    cd /root && \
    ln -s /usr/local/bin/luapp5.3 /usr/local/bin/luapp && \
    \rm -rf /root/lua-5.3.5

# Install hack to run as current user
# ----------------------------------------------------
RUN \
	for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        gpg --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
    done

RUN \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" && \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash", "-l"]
