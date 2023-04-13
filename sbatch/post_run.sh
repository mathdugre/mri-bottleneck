#!/bin/bash
set -e
set -u

# Check if pipeline succeeded.
EXIT_CODE=$?
if [[ ${EXIT_CODE} -ne 0 ]]; then
    echo "FATAL Error: Pipeline failed to complete."
    exit ${EXIT_CODE}
fi

# Generate VTune report
singularity exec --cleanenv \
    -B ~/intel/oneapi/vtune/latest/:/vtune \
    -B ${PROJECT_DIR}:${PROJECT_DIR} \
    ${SIF_IMG} \
    /vtune/bin64/vtune \
    -report hotspots \
    -r ${PROFILING_DIR} \
    -report-output ${PROFILING_DIR}.csv \
    -format csv \
    -csv-delimiter tab \
    -group-by module,function \
    -loop-mode function-only


# Tarball VTune profiling data to reduce inode usage.
tar czf ${PROFILING_DIR}.tar.gz -C $(dirname ${PROFILING_DIR}) $(basename ${PROFILING_DIR})
rm -r ${PROFILING_DIR}

# Transfer pipeline output to storage node.
mkdir -p ${OUTPUT_DIR}
rsync -aLq --info=progress2 ${SLURM_TMPDIR}/output/ ${OUTPUT_DIR}/
rm -rf ${SLURM_TMPDIR}

# Transfer `participant.tsv` file for further use.
rsync -aLq --info=progress2 \
    ${DATA_DIR}/participants.tsv \
    ${OUTPUT_DIR}/participants.tsv

# Delete temporary script
rm ${TMP_SCRIPT}/${RANDOM_STRING}.sh
