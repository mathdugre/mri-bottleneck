FROM ubuntu:focal-20221019

ENV DEBIAN_FRONTEND="noninteractive" \
LANG="en_US.UTF-8" \
LC_ALL="en_US.UTF-8"

RUN : \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      python2 \
      git \
      wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && :

RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py
RUN python2 fslinstaller.py -V 6.0.6.4 -d /opt/fsl

SHELL ["/bin/bash", "-c"]
ENV FSLDIR=/opt/fsl \
    FSLDEVDIR=/opt/fsl-dev
ENV PATH="$FSLDIR/share/fsl/bin:${PATH}"
RUN : \
    && source $FSLDIR/etc/fslconf/fsl.sh \
    && source $FSLDIR/etc/fslconf/fsl-devel.sh \
    && source $FSLDIR/bin/activate \
    && for f in $(ls -d $FSLDIR/src/*/ | grep -v fsl-znzlib) ; do cd $f; make CFLAGS=-g && make install; done \
    && :

RUN : \
    && echo 'export FSLDIR=/opt/fsl' >> /etc/bash.bashrc \
    && echo 'export FSLDEVDIR=/opt/fsl-dev' >> /etc/bash.bashrc \
    && echo 'source $FSLDIR/etc/fslconf/fsl.sh' >> /etc/bash.bashrc \
    && echo 'source $FSLDIR/etc/fslconf/fsl-devel.sh' >> /etc/bash.bashrc \
    && echo 'source $FSLDIR/bin/activate' >> /etc/bash.bashrc \
    && :

RUN : \
    && echo 'export FSLDIR=/opt/fsl' >> /fsl_env.sh \
    && echo 'export FSLDEVDIR=/opt/fsl-dev' >> /fsl_env.sh \
    && echo 'source $FSLDIR/etc/fslconf/fsl.sh' >> /fsl_env.sh \
    && echo 'source $FSLDIR/etc/fslconf/fsl-devel.sh' >> /fsl_env.sh \
    && echo 'source $FSLDIR/bin/activate' >> /fsl_env.sh \
    && :