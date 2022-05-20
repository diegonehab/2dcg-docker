FROM ubuntu:20.04 as builder

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
        libgsl-dev \
        liblapacke-dev \
        libreadline-dev \
        pkg-config \
        unzip \
        subversion \
        libwebp-dev clang-9 libjpeg-turbo8-dev python mesa-common-dev \
        vim \
        wget \
        zlib1g-dev \
    && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-9 100 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 100

COPY b64.pc /usr/local/lib/pkgconfig/

# Install Lua 5.3.6 compiled for C++
# ----------------------------------------------------
COPY luapp.patch /root
COPY luapp53.pc /usr/local/lib/pkgconfig/

RUN \
    cd /root && \
    wget https://www.lua.org/ftp/lua-5.3.6.tar.gz && \
    tar -zxvf lua-5.3.6.tar.gz && \
    cd /root/lua-5.3.6 && \
    patch -p1 < ../luapp.patch && \
    make -j$(nproc) CC=g++ MYCFLAGS="-x c++ -fopenmp" MYLIBS="-lgomp" linux && \
    make install && \
    cd /root && \
    ln -s /usr/local/bin/luapp5.3 /usr/local/bin/luapp && \
    \rm -rf /root/lua-5.3.6

# Install MoonJit compiled for C++
# ----------------------------------------------------
RUN \
    cd /root && \
    wget https://github.com/moonjit/moonjit/archive/2.2.0.tar.gz && \
    tar -zxvf 2.2.0.tar.gz && \
    cd moonjit-2.2.0 && \
    make -j$(nproc) && \
    make install && \
    cd /root && \
    \rm -rf moonjit-2.2.0


# Install antigrain stroker
# ----------------------------------------------------
COPY agg/agg-stroker.pc /usr/local/lib/pkgconfig/
COPY agg/agg.patch /root

RUN \
    cd /root && \
    svn checkout -r134 https://svn.code.sf.net/p/agg/svn/ agg && \
    mv agg/agg-web/agg-2.5.tar.gz . && \
    \rm -rf agg && \
    tar -zxvf agg-2.5.tar.gz && \
    cd agg-2.5 && \
    patch -p1 < ../agg.patch && \
    make -j$(nproc) && \
    mkdir -p /usr/local/include/strokers/agg2 && \
    mkdir -p /usr/local/lib/pkgconfig && \
    cp -r include/* /usr/local/include/strokers/agg2 && \
    cp src/libagg.a /usr/local/lib/libagg-stroker.a && \
    cd .. && \
    \rm -rf agg-2.5 && \
    \rm -rf agg-2.5.tar.gz

# Install cairo stroker
# ----------------------------------------------------
COPY cairo/cairo-stroker.pc /usr/local/lib/pkgconfig
COPY cairo/cairo-traps.patch /root
COPY cairo/cairo-polygon.patch /root
COPY cairo/cairo-tristrip.patch /root

RUN \
    cd /root && \
    wget http://cairographics.org/snapshots/cairo-1.17.2.tar.xz && \
    tar -Jxvf cairo-1.17.2.tar.xz && \
    cd cairo-1.17.2/src && \
    patch < ../../cairo-traps.patch && \
    patch < ../../cairo-polygon.patch && \
    patch -p2 < ../../cairo-tristrip.patch && \
    cd .. && \
    wget https://www.cairographics.org/releases/pixman-0.38.0.tar.gz && \
    tar -zxvf pixman-0.38.0.tar.gz && \
    cd pixman-0.38.0 && \
    ./configure -enable-shared=no --enable-gtk=no --enable-libpng=no --with-pic=yes && \
    make -j$(nproc) && \
    make install && \
    mv /usr/local/lib/pkgconfig/pixman-1.pc /usr/local/lib/pkgconfig/cairo-stroker-pixman-1.pc && \
    cd .. && \
    pixman_CFLAGS="$(pkg-config --cflags cairo-stroker-pixman-1)" pixman_LIBS="$(pkg-config --libs cairo-stroker-pixman-1)" ./configure --enable-xlib=no --enable-xlib-xrender=no --enable-xcb=no --enable-xlib-xcb=no --enable-xcb-shm=no --enable-qt=no --enable-png=no --enable-gl=no --enable-cogl=no --enable-ft=no --enable-fc=no --enable-ps=no --enable-pdf=no --enable-svg=no --enable-glx=no --enable-pthread=yes --enable-gobject=no --disable-valgrind --enable-script=no --enable-interpreter=no --enable-trace=no --with-pic=yes && \
    make -j$(nproc) && \
    \rm -rf /usr/local/include/cairo && \
    make install && \
    \rm -f /usr/local/lib/libcairo-* && \
    \rm -f /usr/local/lib/libcairo*so* && \
    \rm -rf /usr/local/lib/cairo && \
    \rm -rf /usr/local/lib/pkgconfig/cairo.pc && \
    mv /usr/local/lib/libcairo.a /usr/local/lib/libcairo-stroker.a && \
    mv /usr/local/lib/libcairo.la /usr/local/lib/libcairo-stroker.la && \
    cp src/cairoint.h /usr/local/include/cairo && \
    cp src/cairo*private.h /usr/local/include/cairo && \
    cp config.h /usr/local/include/cairo && \
    mv /usr/local/include/cairo /usr/local/include/strokers && \
    cd .. && \
    \rm -rf cairo-1.17.2 && \
    \rm -rf cairo-1.17.2.tar.xz

# Install ghostscript stroker
# ----------------------------------------------------
COPY gs/ghostscript-stroker.pc /usr/local/lib/pkgconfig
COPY gs/ghostscript.patch /root

RUN \
    cd /root && \
    wget https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs926/ghostscript-9.26.tar.gz && \
    tar -zxvf ghostscript-9.26.tar.gz && \
    patch -p0 < ghostscript.patch && \
    cd ghostscript-9.26 && \
    CXXFLAGS=-fpic CFLAGS=-fpic ./configure --disable-openjpeg --with-drivers=PS --disable-fontconfig --disable-compile-inits --disable-contrib --disable-threading --disable-dbus --disable-freetype --disable-cups --disable-gtk --without-libidn --with-libiconv=no --without-libtiff --without-pdftoraster --without-ijs  --without-luratech --without-jbig2dec && \
    make -j$(nproc) && \
    cd obj && \
    \rm -f inobtokn.o inouparm.o gsiodevs.o && \
    \rm -f libghostscript-stroker.a && \
    ar rcu libghostscript-stroker.a *.o && \
    cp libghostscript-stroker.a /usr/local/lib && \
    cd .. && \
    \rm -rf /usr/local/include/strokers/ghostscript && \
    mkdir -p /usr/local/include/strokers/ghostscript/base && \
    cp base/*.h /usr/local/include/strokers/ghostscript/base && \
    cp obj/arch.h /usr/local/include/strokers/ghostscript && \
    cd .. && \
    \rm -rf ghostscript-9.26 && \
	\rm -rf ghostscript-9.26.tar.xz

# Install livarot (Inkscape) stroker
# ----------------------------------------------------
COPY livarot/livarot.patch /root
COPY livarot/makefile.livarot /root
COPY livarot/livarot-stroker.pc /usr/local/lib/pkgconfig

RUN \
    cd /root && \
    wget https://media.inkscape.org/dl/resources/file/inkscape-0.92.4.tar.bz2 && \
    tar -jxvf inkscape-0.92.4.tar.bz2 && \
    patch -p0 < livarot.patch && \
    cd inkscape-0.92.4 && \
    touch src/config.h && \
    make -j$(nproc) -f ../makefile.livarot && \
    cp liblivarot-stroker.a /usr/local/lib && \
    \rm -rf /usr/local/include/strokers/livarot && \
    mkdir -p /usr/local/include/strokers/livarot && \
    mkdir -p /usr/local/include/strokers/livarot/livarot && \
    cp src/livarot/*.h /usr/local/include/strokers/livarot/livarot && \
    mkdir -p /usr/local/include/strokers/livarot/helper && \
    cp src/helper/*.h /usr/local/include/strokers/livarot/helper && \
    mkdir -p /usr/local/include/strokers/livarot/2geom && \
    cp src/2geom/*.h /usr/local/include/strokers/livarot/2geom && \
    touch /usr/local/include/strokers/livarot/config.h && \
    cd .. && \
    \rm -rf inkscape-0.92.4 && \
    \rm -rf inkscape-0.92.4.tar.bz2

# Install mupdf stroker
# ----------------------------------------------------
COPY mupdf/mupdf-stroker.pc /usr/local/lib/pkgconfig
COPY mupdf/mupdf.patch /root

RUN \
    cd /root && \
    wget https://mupdf.com/downloads/archive/mupdf-1.14.0-source.tar.xz && \
    tar -Jxvf mupdf-1.14.0-source.tar.xz && \
    patch -p0 < mupdf.patch && \
    cd mupdf-1.14.0-source && \
    HAVE_GLFW=no HAVE_X11=no XCFLAGS="-fPIC -DNO_ICC" verbose=yes make libs && \
    cp build/release/libmupdf.a /usr/local/lib/libmupdf-stroker.a && \
    cp build/release/libmupdf-third.a /usr/local/lib && \
    \rm -rf /usr/local/include/strokers/mupdf && \
    cp -r include/mupdf /usr/local/include/strokers && \
    mkdir -p /usr/local/include/strokers/mupdf/private/fitz && \
    cp source/fitz/*.h /usr/local/include/strokers/mupdf/private/fitz/ && \
    cd .. && \
    \rm -rf mupdf-1.14.0-source && \
    \rm -rf mupdf-1.14.0-source.tar.xz

# Install skia
# ----------------------------------------------------
COPY skia/skia.pc /usr/local/lib/pkgconfig

RUN \
    cd /root && \
    git clone --depth 1 'https://chromium.googlesource.com/chromium/tools/depot_tools.git' && \
    export PATH="${PWD}/depot_tools:${PATH}" && \
    git clone --single-branch --branch 'canvaskit/0.34.0' --depth 1 https://skia.googlesource.com/skia.git && \
    cd skia && \
    python tools/git-sync-deps && \
    bin/gn gen out/Static --args='is_official_build=true skia_use_system_harfbuzz=false cc="clang-9" cxx="clang++-9"' && \
    ninja -C out/Static && \
    mkdir /usr/local/include/skia && \
    cp -r include /usr/local/include/skia && \
    mkdir -p /usr/local/include/skia/third_party/skcms && \
    cp third_party/skcms/*.h /usr/local/include/skia/third_party/skcms && \
    mkdir /usr/local/lib/skia && \
    cp out/Static/*.a /usr/local/lib/skia && \
    cd .. && \
    \rm -rf skia && \
    \rm -rf depot_tools

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

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
        libgsl-dev \
        liblapacke-dev \
        libreadline-dev \
        qt5-default \
        pkg-config \
        unzip \
        subversion \
        libwebp-dev libjpeg-turbo8-dev mesa-common-dev \
        vim \
        wget \
        zlib1g-dev \
    && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/ /usr/local

# Install Agner Fog's vcl
# ----------------------------------------------------
RUN \
    cd /root && \
    wget https://github.com/vectorclass/version2/archive/refs/tags/v2.01.04.tar.gz && \
    tar -zxvf v2.01.04.tar.gz && \
    mv version2-2.01.04 /usr/local/include/vcl && \
    \rm -rf v2.01.04.tar.gz

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
