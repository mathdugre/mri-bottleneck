#!/bin/sh
set -e
set -u

NTHREAD=32
PROJECT_DIR=/mnt/lustre/mathdugre/mri-bottleneck
SIF_DIR=$HOME/containers

# Datatset preparation
cat << EOF
########################
# Datatset preparation #
########################
EOF
DATA_DIR=${PROJECT_DIR}/datasets/LMU_2
DATALAD_URL="///corr/RawDataBIDS/LMU_2"
echo "datalad install -gr -J\$(nproc) --source ${DATALAD_URL} ${DATA_DIR}"

N_SUBJECTS=$(awk 'END {print NR-1}' ${DATA_DIR}/participants.tsv)

# Pipeline profiling
# PROJECT_DIR=${PROJECT_DIR}/test
cat << EOF

######################
# Pipeline profiling #
######################
EOF
## Anatomical MRI preprocessing
echo sbatch --array=1-${N_SUBJECTS}%6 --cpus-per-task=${NTHREAD} sbatch/ants/brainExtraction.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}
echo sbatch --array=1-${N_SUBJECTS}%6 --cpus-per-task=${NTHREAD} sbatch/ants/brainExtraction-fp.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%6 --cpus-per-task=${NTHREAD} sbatch/fsl/fast.sh $SIF_DIR/fsl-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%6 --cpus-per-task=${NTHREAD} sbatch/ants/registrationSyN.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}
echo sbatch --array=1-${N_SUBJECTS}%6 --cpus-per-task=${NTHREAD} sbatch/ants/registrationSyN-fp.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

# TODO
# reconall

## BOLD preprecessing

# TODO
# FSL MCFLIRT
# AFNI 3dTshift
# FSL FLIRT
# FreeSurfer bbregister (?h.white)
# FSL MELODIC
