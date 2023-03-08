FROM centos:centos7.9.2009

RUN : \
    && yum -y update \
    && yum install -y epel-release \
    && yum repolist \
    && yum install -y \
      dnf \
      expat-devel \
      libX11-devel \
      mesa-libGL-devel \
      openblas-devel \
      python3 \
      vtk-devel \
      zlib-devel \
    && dnf group install -y "Development Tools" \
    && :

ARG FSL_VERSION="6.0.5.2"
RUN : \
    && echo "Downloading FSL ..." \
    && mkdir -p /tmp/fsl \
    && curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-${FSL_VERSION}-sources.tar.gz \
    | tar -xz -C /tmp/fsl --strip-components 1 \
    && :

RUN : \
    && export FSL_CONFIG="/tmp/fsl/config" \
    && sed -i 's:VTKDIR_INC = .*:VTKDIR_INC = /usr/include/vtk:g' ${FSL_CONFIG}/buildSettings.mk \
    && sed -i 's:VTKDIR_LIB = .*:VTKDIR_LIB = /usr/lib64/vtk:g' ${FSL_CONFIG}/buildSettings.mk \
    && sed -i 's:VTKSUFFIX = .*:VTKSUFFIX = "":g' ${FSL_CONFIG}/buildSettings.mk \
    && sed -i 's:${MAKE} -k ${MAKEOPTIONS}:${MAKE} -k ${MAKEOPTIONS} debug:g' ${FSL_CONFIG}/common/buildproj \
    && sed -i 's:fdt_MASTERBUILD     = COMPILE_GPU = 1:fdt_MASTERBUILD     = COMPILE_GPU = 0:g' ${FSL_CONFIG}/buildSettings.mk \
    && sed -i 's:ptx2_MASTERBUILD    = COMPILE_GPU = 1:ptx2_MASTERBUILD    = COMPILE_GPU = 0:g' ${FSL_CONFIG}/buildSettings.mk \
    && alternatives --install /usr/bin/python python /usr/bin/python2 50 \
    && alternatives --install /usr/bin/python python /usr/bin/python3 60 \
    && alternatives --set python /usr/bin/python3 \
    && :

# # FSL FEEDS (Testing suite)
# RUN curl -fsSL https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-${FSL_VERSION}-feeds.tar.gz \
#     | tar -xz -C /tmp/fsl-${FSL_VERSION}-feeds

RUN : \
    && cd /tmp/fsl \
    && ./build \
    && :

# TODO Use multi-stage to reduce image size.
