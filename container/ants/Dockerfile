FROM ubuntu:jammy
ARG nthreads 4

# Prepare environment
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-utils \
    autoconf \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    git \
    libssl-dev \
    libtool \
    lsb-release \
    netbase \
    pkg-config \
    unzip \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    :

WORKDIR $HOME/src
ARG CMAKE_VERSION="3.25.0-rc3"
RUN : \
    && mkdir -p ~/src \
    && curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
    | tar -xz -C ~/src \
    && cd ~/src/cmake-${CMAKE_VERSION} \
    && ./bootstrap \
    && make \
    && make install \
    && :

# WORKDIR $HOME/src
# ENV workingDir=$PWD \
#     buildDir=$workingDir/build 

ARG ANTs_VERSION "v2.4.2"
RUN : \
    && git clone https://github.com/ANTsX/ANTs.git \
    && cd ANTs \
    && git checkout ${ANTs_VERSION}\
    # && cd - \
    # && mkdir $buildDir \
    # && cd $buildDir \
    && cmake \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_VTK=OFF \
    -DSuperBuild_ANTS_USE_GIT_PROTOCOL=OFF \
    -DBUILD_TESTING=OFF \
    -DRUN_LONG_TESTS=OFF \
    -DRUN_SHORT_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Debug \
    # $workingDir/ANTs 2>&1 | tee cmake.log \
    . 2>&1 | tee cmake.log \
    && make -j $nthreads 2>&1 | tee build.log \
    && cd ANTS-build \
    && make install 2>&1 | tee install.log \
    && :

WORKDIR $HOME
