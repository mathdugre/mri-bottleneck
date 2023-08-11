FROM ubuntu:focal-20221019
ARG GCC_VERSION="releases/gcc-9.4.0"

RUN : \
    && apt update \
    && apt install -y --no-install-recommends \
        git \
    && :

# Dowload GCC source
ENV GCC_SOURCE=/src/gcc
RUN : \
    && mkdir -p ${GCC_SOURCE} \
    && git clone git://gcc.gnu.org/git/gcc.git ${GCC_SOURCE} \
    && cd ${GCC_SOURCE} \
    && git checkout ${GCC_VERSION} \
    && :

# Download prerequisites to build GCC
RUN : \
    && apt install -y --no-install-recommends \
        build-essential \
        bzip2 \
        curl \
        file \
        flex \
        python3 \
    && cd ${GCC_SOURCE} \
    && contrib/download_prerequisites \
    && :

# Configure GCC
ENV GCC_BUILD_DIR=/tmp/build/gcc
WORKDIR ${GCC_BUILD_DIR}
RUN : \
    && mkdir -p ${GCC_BUILD_DIR} \
    && ${GCC_SOURCE}/configure -v \
        --build=x86_64-linux-gnu \
        --host=x86_64-linux-gnu \
        --target=x86_64-linux-gnu \
        --enable-checking=release \
        --enable-languages=c,c++,fortran \
        --disable-multilib \
    && :

# Build & Install GCC
RUN : \
    && make CXXFLAGS="-g3" -j \
    && make install-strip \
    && :

# Clean-up
RUN : \
    && rm -rf ${GCC_SOURCE} ${GCC_BUILD_DIR} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* \
    &&:

WORKDIR /

