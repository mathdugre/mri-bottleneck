FROM mathdugre/intel-compilers:debug-info as builder

# Prepare environment
ENV DEBIAN_FRONTEND="noninteractive"
RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
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

# Get FreeSurfer source
ARG FS_TAG="v7.3.3"
ENV FS_SOURCE=/tmp/freesurfer/source
RUN : \
    && git clone https://github.com/freesurfer/freesurfer.git ${FS_SOURCE} \
    && cd ${FS_SOURCE} \
    && git checkout ${FS_TAG}\
    && git remote add datasrc https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/repo/annex.git \
    && git fetch datasrc \
    && git-annex get . \
    && :

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

RUN : \
    && sed -i 's:-nofor_main:-nofor-main:g' ${FS_SOURCE}/talairach_avi/CMakeLists.txt \
    && :

# Hack to fix version for nipype
RUN : \
    && sed -i 's:set(BUILD_STAMP "freesurfer-local-build-\${TODAY}":set(BUILD_STAMP "freesurfer-local-build-'${FS_TAG}'-\${TODAY}-debug":g' ${FS_SOURCE}/CMakeLists.txt \
    && :

# Build FreeSurfer
RUN : \
    && mkdir -p /tmp/freesurfer/build \
    && cd /tmp/freesurfer/build \
    && mkdir -p /opt/freesurfer \
    && . /opt/intel/oneapi/setvars.sh --force \
    && cmake \
    -DBUILD_GUIS=OFF \
    -DFS_PACKAGES_DIR=/tmp/freesurfer/packages \
    -DCMAKE_INSTALL_PREFIX=/opt/freesurfer \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=icx \
    -DCMAKE_CXX_COMPILER=icpx \
    -DCMAKE_FORTRAN_COMPILER=ifx \
    -DWARNING_AS_ERROR=OFF \
    /tmp/freesurfer/source \
    && make -j \
    && make install \
    && :

# Move required MNI packages to the build package
RUN mv /tmp/freesurfer/packages/mni/current /opt/freesurfer/mni

FROM mathdugre/intel-compilers:debug-info
COPY --from=builder /opt/freesurfer /opt/freesurfer

ENV DEBIAN_FRONTEND="noninteractive"
RUN : \
    && apt-get update \
    && apt install -y --no-install-recommends --fix-missing \
        bc \
        file \
        libgtk-3-dev \
        libnetpbm10-dev \
        gfortran \
        libblas-dev \
        liblapack-dev \
        libglu1-mesa-dev \
        libx11-dev \
        libxi-dev \
        libxml2-utils \
        libxmu-dev \
        libxmu-headers \
        libxt-dev \
        python3 \
        python3-dev \
        python3-pip \
        tcsh \
        xxd \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* \
    && :

# setup fs env
ENV OS="Linux" \
    LD_LIBRARY_PATH="/opt/freesurfer/lib/vtk:/opt/freesurfer/lib:$LD_LIBRARY_PATH" \
    PATH="/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:$PATH" \
    FSPATH="/opt/freesurfer/bin" \
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

# Dependencies to run recon-all extern skull-strip alignment.
RUN : \
    && pip3 install \
        nibabel \
        nilearn \
        nipype \
        numpy \
    && :

# Setup Intel OpenMP
ENV LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/lib:$LD_LIBRARY_PATH"

WORKDIR /data

CMD ["/bin/bash"]
