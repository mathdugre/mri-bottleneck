#!/bin/bash

#SBATCH -J antsBrainExtraction
#SBATCH --array=1
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
# -------------------------
#SBATCH -o log/%x-%A-%a.out
#SBATCH -e log/%x-%A-%a.err
# -------------------------
set -e
set -u

# Setup environment and parse args.
source ./sbatch/utils.sh brainExtraction $@
[[ -z ${SLURM_ARRAY_TASK_ID:+x} ]] && SLURM_ARRAY_TASK_ID=1

# Transfer dataset to compute node.
mkdir -p ${SLURM_TMPDIR}/input/sub-${SUBJECT_ID}
rsync -aLq --info=progress2 \
    --exclude "output" \
    ${INPUT_DIR}/sub-${SUBJECT_ID}/ \
    ${SLURM_TMPDIR}/input/sub-${SUBJECT_ID}/

RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
VTUNE_DIR=${PROFILING_DIR}/ants/brainExtraction/${DATASET}/sub-${SUBJECT_ID}/${RANDOM_STRING}
echo "[INFO] Writing profiling data in directory: ${VTUNE_DIR}"

TMPLT="/opt/templates/OASIS"
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREAD
singularity exec --cleanenv \
    -B ~/intel/oneapi/vtune/latest/:/vtune \
    -B ${SLURM_TMPDIR}:/data \1
    ${SIF_IMG} \
    /vtune/bin64/vtune \
    -collect hotspot \
    -knob enable-stack-collection=true \
    -result-dir ${VTUNE_DIR}\
    antsBrainExtraction.sh \
    -d 3 \
    -a /data/input/sub-${SUBJECT_ID}/ses-1/anat/sub-${SUBJECT_ID}_ses-1_run-1_T1w.nii.gz \
    -e ${TMPLT}/T_template0.nii.gz \
    -m ${TMPLT}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -o /data/output/${DATASET}/sub-${SUBJECT_ID}

EXIT_CODE=$?

# Transfer pipeline output to storage node.
mkdir -p ${OUTPUT_DIR}
rsync -aq --info=progress2 --exclude "input" ${SLURM_TMPDIR}/ ${OUTPUT_DIR}
rm -rf ${SLURM_TMPDIR}

exit ${EXIT_CODE}
