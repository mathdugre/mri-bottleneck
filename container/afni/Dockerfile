FROM ubuntu:jammy

# Prepare environment
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
    libtool \
    lsb-release \
    netbase \
    pkg-config \
    unzip \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    :

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

RUN : \
    && mkdir -p ~/src/afni \
    && curl -fsSl --retry 5 curl https://afni.nimh.nih.gov/pub/dist/tgz/afni_src.tgz \
    | tar -xz -C ~/src/afni \
    && :
# TODO Makefile instructions.