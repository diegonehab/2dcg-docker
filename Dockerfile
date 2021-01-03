FROM ubuntu:20.04

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
        libcairo2-dev \
        libfreetype6-dev \
        libharfbuzz-dev \
        libicu-dev \
        libpng-dev \
        liblapacke-dev \
        libreadline-dev \
        pkg-config \
        unzip \
        vim \
        wget \
        zlib1g-dev \
    && \
    rm -rf /var/lib/apt/lists/*

COPY b64.pc /usr/local/lib/pkgconfig/

# Install Lua 5.3.6 compiled for C++
# ----------------------------------------------------
COPY luapp.patch /root
COPY luapp53.pc /usr/local/lib/pkgconfig/

RUN \
    NPROC=$(nproc) && \
    cd /root && \
    wget https://www.lua.org/ftp/lua-5.3.6.tar.gz && \
    tar -zxvf lua-5.3.6.tar.gz && \
    cd /root/lua-5.3.6 && \
    patch -p1 < ../luapp.patch && \
    make -j$NPROC CC=g++ MYCFLAGS="-x c++ -fopenmp" MYLIBS="-lgomp" linux && \
    make install && \
    cd /root && \
    ln -s /usr/local/bin/luapp5.3 /usr/local/bin/luapp && \
    \rm -rf /root/lua-5.3.6

# Install MoonJit compiled for C++
# ----------------------------------------------------
RUN \
    NPROC=$(nproc) && \
    cd /root && \
    wget https://github.com/moonjit/moonjit/archive/2.2.0.tar.gz && \
    tar -zxvf 2.2.0.tar.gz && \
    cd moonjit-2.2.0 && \
    make -j$NPROC && \
    make install && \
    cd /root && \
    \rm -rf moonjit-2.2.0

# Install workaround to run as current user
# ----------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN \
    chmod +x /usr/local/bin/entrypoint.sh

RUN \
    cd $BUILD_BASE && \
    git clone --branch v0.2 --depth 1 https://github.com/ncopa/su-exec.git && \
    cd su-exec && \
    if [ `git rev-parse --verify HEAD` != 'f85e5bde1afef399021fbc2a99c837cf851ceafa' ]; then exit 1; fi && \
    make && \
    cp su-exec /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash", "-l"]
