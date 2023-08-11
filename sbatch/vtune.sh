#!/bin/bash
set -e
set -u

echo "Command to profile: $@"

[[ -z ${SIF_OPTION:+x} ]] && SIF_OPTION=""

singularity exec --cleanenv \
    -B ~/intel/oneapi/vtune/latest/:/vtune \
    -B ${SLURM_TMPDIR}:/data \
    -B ${PROJECT_DIR}:${PROJECT_DIR} \
    ${SIF_OPTION} \
    ${SIF_IMG} \
    /vtune/bin64/vtune \
    -collect hpc-performance \
    -no-auto-finalize \
    -data-limit=0 \
    -knob enable-stack-collection=true \
    -knob analyze-openmp=true \
    -result-dir ${PROFILING_DIR} \
    $@