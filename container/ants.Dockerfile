FROM cmake:focal-20221019 as builder

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      bc \
      ninja-build \
      git \
      software-properties-common \
      unzip \
      wget \
      zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && :

# TODO Replace version on next release.
# This commit build non-release version with the Scripts.
# ARG ANTs_VERSION="v2.4.2"
ARG ANTs_VERSION="f022d4f978374b9fb268978da4fcc134e91761bb"
RUN : \
    && git clone https://github.com/ANTsX/ANTs.git /tmp/ants/source \
    && cd /tmp/ants/source \
    && git checkout ${ANTs_VERSION} \
    && mkdir -p /tmp/ants/build \
    && cd /tmp/ants/build \
    && mkdir -p /opt/ants \
    && git config --global url."https://".insteadOf git:// \
    && cmake \
      -GNinja \
      -DBUILD_TESTING=ON \
      -DRUN_LONG_TESTS=OFF \
      -DRUN_SHORT_TESTS=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/ants \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      /tmp/ants/source \
    && cmake --build . --parallel \
    && cd ANTS-build \
    && cmake --install . \
    && :

# Need to set library path to run tests
ENV LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

RUN cd /tmp/ants/build/ANTS-build \
    && cmake --build . --target test

RUN wget https://ndownloader.figshare.com/files/3133832 -O oasis.zip \
    && unzip oasis.zip -d /opt \
    && rm -rf oasis.zip

FROM ubuntu:focal-20221019
COPY --from=builder /opt/ants /opt/ants
COPY --from=builder /opt/MICCAI2012-Multi-Atlas-Challenge-Data /opt/templates/OASIS

ENV ANTSPATH="/opt/ants/bin" \
    PATH="/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"
RUN : \
    && apt-get update \
    && apt install -y --no-install-recommends \
      bc \
      zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && :

WORKDIR /data

CMD ["/bin/bash"]
