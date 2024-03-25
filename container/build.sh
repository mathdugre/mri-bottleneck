#!/bin/sh
set -e
set -u

# Compilers
docker build -t mathdugre/cmake:debug-info -f cmake.Dockerfile .
docker build -t mathdugre/intel-compilers:debug-info -f intel-compilers.Dockerfile .

# Sub-workflows
docker build -t mathdugre/afni:debug-info -f afni.Dockerfile .
docker build -t mathdugre/ants:debug-info -f ants.Dockerfile .
docker build -t mathdugre/fsl:debug-info -f cmake.Dockerfile .
docker build -t mathdugre/freesurfer:debug-info -f freesurfer.Dockerfile .

# fMRIPrep
docker build -t mathdugre/fmriprep:debug-info -f fmriprep.Dockerfile .
