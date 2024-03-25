FROM mathdugre/intel-compilers:debug-info as compilers
FROM mathdugre/freesurfer:debug-info as freesurfer
FROM mathdugre/ants:debug-info as ants
FROM mathdugre/fsl:debug-info as fsl
FROM mathdugre/afni:debug-info as afni


FROM nipreps/fmriprep:23.0.2
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
        # xxd \
        zlib1g-dev \
    && :

###################
# Intel compilers #
###################
COPY --from=compilers /opt/intel /opt/intel

##############
# FreeSurfer #
##############
COPY --from=freesurfer /opt/freesurfer /opt/freesurfer

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
    && apt install -y --no-install-recommends \
        python3-setuptools \
    && python3 -m pip install \
        nibabel \
        nilearn \
        nipype \
        numpy \
    && :

# Setup Intel OpenMP
ENV LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/lib:$LD_LIBRARY_PATH"

########
# ANTS #
########
COPY --from=ants /opt/ants /opt/ants
COPY --from=ants /opt/templates/ /opt/templates

ENV ANTSPATH="/opt/ants/bin" \
    PATH="/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

#######
# FSL #
#######
COPY --from=fsl /opt/fsl /opt/fsl
COPY --from=fsl /opt/fsl-dev /opt/fsl-dev

ENV FSLDIR=/opt/fsl \
    FSLDEVDIR=/opt/fsl-dev
ENV PATH="$FSLDIR/share/fsl/bin:${PATH}"

RUN : \
    && echo 'export FSLDIR=/opt/fsl' >> /fsl_env.sh \
    && echo 'export FSLDEVDIR=/opt/fsl-dev' >> /fsl_env.sh \
    && echo 'source $FSLDIR/etc/fslconf/fsl.sh' >> /fsl_env.sh \
    && echo 'source $FSLDIR/etc/fslconf/fsl-devel.sh' >> /fsl_env.sh \
    && echo 'source $FSLDIR/bin/activate' >> /fsl_env.sh \
    && :

########
# AFNI #
########
COPY --from=afni /tmp/afni/src /opt/afni

ENV INSTALLDIR /opt/afni
ENV AFNI_PLUGINPATH "$INSTALLDIR"
ENV PATH "$INSTALLDIR:${PATH}"

####################
# Container config #
####################
RUN : \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* \
    && :

WORKDIR /data
CMD ["/bin/bash"]
