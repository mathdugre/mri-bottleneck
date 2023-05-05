#!/bin/bash

singularity exec --cleanenv \
    -B ~/intel/oneapi/vtune/latest/:/vtune \
    -B ${SLURM_TMPDIR}:/data \
    -B ${PROFILING_DIR}:${PROFILING_DIR} \
    ${SIF_IMG} \
    /vtune/bin64/vtune \
    -collect hpc-performance \
    -knob enable-stack-collection=true \
    -knob collect-memory-bandwidth=true \
    -knob analyze-openmp=false \
    -result-dir ${VTUNE_DIR} \
    <script.sh>
