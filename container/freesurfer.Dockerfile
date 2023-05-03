# FROM ubuntu:focal-20221019 as builder
FROM cmake:focal-20221019

# Prepare environment
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      gfortran \
      git \
      git-annex \
      libblas-dev \
      liblapack-dev \
      libglu1-mesa-dev \
      libx11-dev \
      libxi-dev \
      libxmu-dev \
      libxmu-headers \
      libxt-dev \
      python2 \
      python2-dev \
      python3 \
      python3-dev \
      python3-distutils \
      python3-pip \
      tcsh \
      xxd \
      wget \
      zlib1g-dev \
    && :

# Ideally, freesurfer should be compiled with gcc 4.8
# ref: https://surfer.nmr.mgh.harvard.edu/fswiki/BuildRequirements

# gcc-8 was used recently to build on Ubuntu20
#ref: https://github.com/freesurfer/freesurfer/issues/951
RUN : \
    # && echo "deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse" \
    #   | tee /etc/apt/sources.list.d/focal.list \
    # && apt-get update \
    && apt-get install -y --no-install-recommends \
      g++-8 \
      gcc-8 \
      gfortran-8 \
    && update-alternatives \
      --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
      --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
      --slave /usr/bin/gcov gcov /usr/bin/gcov-8 \
      --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-8 \
    && update-alternatives --set gcc /usr/bin/gcc-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && :

ARG FS_VERSION="v7.3.3"
ENV FS_SOURCE=/tmp/freesurfer/source
RUN : \
    && git clone https://github.com/freesurfer/freesurfer.git ${FS_SOURCE} \
    && cd ${FS_SOURCE} \
    && git checkout ${FS_VERSION}\
    && git remote add datasrc https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/repo/annex.git \
    && git fetch datasrc \
    && git-annex get . \
    && :

# TODO move to dependency installation section.
RUN apt update && apt install -y 

# Build required packages
ENV PKG_SOURCE=/tmp/freesurfer/source/packages/source
RUN : \
    && curl -fsSL https://surfer.nmr.mgh.harvard.edu/pub/data/fspackages/prebuilt/centos7-packages.tar.gz \
      | tar -xz -C /tmp/freesurfer \
    && sed -i 's:make linux-g++:make CFLAGS="-g $CFLAGS" linux-g++:g' ${PKG_SOURCE}/build_ann.sh \
    && sed -i 's:^make$:make CFLAGS="-g $CFLAGS":g' ${PKG_SOURCE}/build_gts.sh \
    && sed -i 's:-DCMAKE_BUILD_TYPE\:STRING=Release:-DCMAKE_BUILD_TYPE\:STRING=RelWithDebInfo:g' ${PKG_SOURCE}/build_itk.sh \
    && sed -i 's:--with-debugging=no:--with-debugging=yes:g' ${PKG_SOURCE}/build_petsc.sh \
    && sed -i 's:make -j:make CFLAGS="-g $CFLAGS" -j:g' ${PKG_SOURCE}/build_petsc.sh \
    && sed -i 's:^make$:make CFLAGS="-g $CFLAGS":g' ${PKG_SOURCE}/build_petsc.sh \
    && sed -i 's:-DCMAKE_BUILD_TYPE\:STRING=Release:-DCMAKE_BUILD_TYPE\:STRING=RelWithDebInfo:g' ${PKG_SOURCE}/build_vtk.sh \
    # Update ITK version to compile with gcc-8 to gcc-10.
    # Otherwise, error occurs: undefined reference to __pow_finite.
    && curl -fsSL https://github.com/InsightSoftwareConsortium/ITK/releases/download/v4.13.3/InsightToolkit-4.13.3.tar.gz | tar -xz -C /tmp \
    && mv /tmp/InsightToolkit-4.13.3 /tmp/ITK \
    && cd /tmp \
    && tar -czf ${PKG_SOURCE}/itk-4.13.3.tar.gz ITK \
    && sed -i "s:Package('itk',         '4.13.0', 'build_itk.sh',       'itk-4.13.0.tar.gz'):Package('itk',         '4.13.3', 'build_itk.sh',       'itk-4.13.3.tar.gz'):" ${FS_SOURCE}/packages/build_packages.py \
    &&:
RUN : \
    && python3 ${FS_SOURCE}/packages/build_packages.py /tmp/freesurfer/packages \
        --no-petsc \
        --no-gts \
    && :

# Fix issues for build.
# surfa 0.4.2 is used in dev version (b39cfa30b337f2ef2456492d8412352fbc070d4b)
RUN : \
    && sed -i "s:itk/4.13.0:itk/4.13.3:" ${FS_SOURCE}/CMakeLists.txt \
    && sed -i "s:h5py==2.10:h5py==2.10.0:" ${FS_SOURCE}/python/requirements-extra.txt \
    && sed -i "s:surfa==0.0.12:surfa==0.4.2:" ${FS_SOURCE}/python/requirements.txt \
    && :

# Build FreeSurfer
RUN : \
&& mkdir -p /tmp/freesurfer/build \
&& cd /tmp/freesurfer/build \
&& mkdir -p /opt/freesurfer \
&& cmake \
  -DBUILD_GUIS=OFF \
  -DFS_PACKAGES_DIR=/tmp/freesurfer/packages \
  -DCMAKE_INSTALL_PREFIX=/opt/freesurfer \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  /tmp/freesurfer/source \
    && make -j \
    && make install \
    && :

RUN apt install -y vim

# Test FreeSurfer
# RUN cd /tmp/freesurfer/build \
#     && make test

# FROM ubuntu:focal-20221019
# COPY --from=builder /opt/freesurfer /opt/freesurfer

ENV FSPATH="/opt/freesurfer/bin" \
    PATH="/opt/freesurfer/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/freesurfer/lib:$LD_LIBRARY_PATH"
# RUN : \
#     && apt-get update \
#     && apt install -y --no-install-recommends \
#       bc \
#       zlib1g-dev \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#     && :

# RUN : \
#     && apt install -y --no-install-recommends \
#       file \
#       libgtk-3-dev \
#       libnetpbm10-dev \
#     && :

# setup fs env
ENV OS="Linux" \
    PATH="/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    FREESURFER_HOME="/opt/freesurfer" \
    FREESURFER="/opt/freesurfer" \
    SUBJECTS_DIR="/opt/freesurfer/subjects" \
    LOCAL_DIR="/opt/freesurfer/local" \
    FSFAST_HOME="/opt/freesurfer/fsfast" \
    FMRI_ANALYSIS_DIR="/opt/freesurfer/fsfast" \
    FUNCTIONALS_DIR="/opt/freesurfer/sessions"

# set default fs options
ENV FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    FSF_OUTPUT_FORMAT="nii.gz"

# mni env requirements
ENV MINC_BIN_DIR="/opt/freesurfer/mni/bin" \
    MINC_LIB_DIR="/opt/freesurfer/mni/lib" \
    MNI_DIR="/opt/freesurfer/mni" \
    MNI_DATAPATH="/opt/freesurfer/mni/data" \
    MNI_PERL5LIB="/opt/freesurfer/mni/share/perl5" \
    PERL5LIB="/opt/freesurfer/mni/share/perl5"

WORKDIR /data

CMD ["/bin/bash"]
