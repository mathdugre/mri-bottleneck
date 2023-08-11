#!/bin/sh
set -e
set -u

NTHREAD=32
MAX_JOBS=8
PROJECT_DIR=/mnt/lustre/mathdugre/mri-bottleneck
SIF_DIR=/mnt/lustre/mathdugre/containers

# Datatset preparation
cat << EOF
########################
# Datatset preparation #
########################
EOF
DATA_DIR=${PROJECT_DIR}/datasets/ds004513
DATALAD_URL="https://github.com/OpenNeuroDatasets/ds004513.git"
echo "datalad install -gr -J\$(nproc) --source ${DATALAD_URL} ${DATA_DIR}"
## Convert symlink to hardlink to prevent issue with preprocessing
echo "find ${DATA_DIR} -type l -exec bash -c 'ln -f \$(readlink -m \$0) \$0' {} \;"

N_SUBJECTS=$(find ${DATA_DIR} -maxdepth 1 -name "sub-*" | wc -l )

# Pipeline profiling
# PROJECT_DIR=${PROJECT_DIR}/test
cat << EOF

######################
# Pipeline profiling #
######################
EOF
## Anatomical MRI preprocessing
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/ants/brainExtraction.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/ants/brainExtraction-fp.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/fsl/fast.sh $SIF_DIR/fsl-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/ants/registrationSyN.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/ants/registrationSyN-fp.sh $SIF_DIR/ants-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/freesurfer/reconall.sh $SIF_DIR/freesurfer-idebug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

## BOLD preprecessing
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/fsl/mcflirt.sh $SIF_DIR/fsl-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/fsl/flirt.sh $SIF_DIR/fsl-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

# AFNI 3dTshift
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/afni/3dTshift.sh $SIF_DIR/afni-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}

# TODO
# FreeSurfer bbregister (?h.white)
# FSL MELODIC

## fMRIPrep workflow
echo sbatch --array=1-${N_SUBJECTS}%${MAX_JOBS} --cpus-per-task=${NTHREAD} sbatch/fmriprep/full.sh $SIF_DIR/fmriprep-debug.sif -d ${DATA_DIR} -p ${PROJECT_DIR}