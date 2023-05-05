FROM ubuntu:xenial-20210804

ARG AFNI_VERSION="AFNI_22.3.07"

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        tcsh xfonts-base libssl-dev       \
        python3-matplotlib python3-numpy  \
        gsl-bin netpbm                    \
        libjpeg62 xvfb xterm vim curl     \
        gedit evince eog                  \
        libglu1-mesa-dev libglw1-mesa     \
        libxm4 build-essential            \
        libcurl4-openssl-dev libxml2-dev  \
        gnome-terminal nautilus libgomp1  \
        gnome-icon-theme-symbolic         \
        firefox xfonts-100dpi libxtst-dev \
        r-base-dev cmake libxt-dev        \
        libgdal-dev libopenblas-dev       \
        libudunits2-dev                   \
        libxext-dev libmotif-dev          \
        libxpm-dev libxmu-dev libz-dev    \
        libxmu-headers libgsl-dev make    \
        libexpat1-dev libmotif-dev \
        git \
    && :

RUN : \
    && git clone https://github.com/afni/afni.git /tmp/afni \
    && cd /tmp/afni/src \
    && cp ./other_builds/Makefile.linux_ubuntu_22_64 Makefile \
    && make CFLAGS="-g" all \
    && :

ENV INSTALLDIR /tmp/afni/src
ENV AFNI_PLUGINPATH "$INSTALLDIR"
ENV PATH "$INSTALLDIR:${PATH}"

# TODO Use multi-stage to reduce image size.
