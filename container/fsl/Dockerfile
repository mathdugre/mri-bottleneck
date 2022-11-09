FROM ubuntu:jammy
ARG FSL_VERSION="6.0.5.2"

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

# FSL
RUN : \
    && echo "Downloading FSL ..." \
    && mkdir -p ~/src/fsl-${FSL_VERSION} \
    && curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-${FSL_VERSION}-sources.tar.gz \
    | tar -xz -C ~/src/fsl-${FSL_VERSION} --strip-components 1 \
    && :

# # FSL FEEDS (Testing suite)
# RUN curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-${FSL_VERSION}-feeds.tar.gz \
#     | tar -xz -C /opt/fsl-${FSL_VERSION}-feeds