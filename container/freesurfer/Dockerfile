FROM ubuntu:jammy

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
    git-annex \
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

ARG FreeSurfer_VERSION "v7.3.3"
RUN : \
    && git clone https://github.com:freesurfer/freesurfer.git \
    && cd freesurfer \
    && git checkout ${FreeSurfer_VERSION}\
    && git remote add datasrc https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/repo/annex.git \
    && git fetch datasrc \
    && git-annex get . \
    # && cmake \
    # -DFS_PACKAGES_DIR="/path/to/packages" \
    # -DCMAKE_BUILD_TYPE=Debug \
    # ~/src/freesurfer 2>&1 | tee cmake.log \
    # && make -j $nthreads 2>&1 | tee build.log \
    # && make install 2>&1 | tee install.log \
    && :