#!/bin/bash

#SBATCH -J fmriprep-anat-fs
#SBATCH --array=1
#SBATCH --time=UNLIMITED
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
# -------------------------
#SBATCH -o log/%x-%A-%a.out
#SBATCH -e log/%x-%A-%a.err
# -------------------------
set -e
set -u

# Setup environment and parse args.
source ./sbatch/pre_run.sh fmriprep anat-fs -j ${SLURM_CPUS_PER_TASK} $@

# Create an empty directory for output
OUTPUT_DIR=$(dirname ${SLURM_TMPDIR})/fmriprep-outputs
SUBJECT_OUTPUT=${OUTPUT_DIR}/sub-${SUBJECT_ID}
if [ -d "${SUBJECT_OUTPUT}" ]; then rm -Rf ${SUBJECT_OUTPUT}; fi
mkdir -p ${SUBJECT_OUTPUT}

# Create WORK_DIR for fMRIPrep
WORK_DIR=$(dirname ${SLURM_TMPDIR})/fmriprep-${RANDOM_STRING}
mkdir -p ${WORK_DIR}

SIF_OPTION+=" -B ${SUBJECT_OUTPUT}:/output"
SIF_OPTION+=" -B ${WORK_DIR}:/workdir"
export SIF_OPTION+=" -B $HOME/.freesurfer.txt:/opt/freesurfer/.license"
cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
FS_LICENSE=/opt/freesurfer/.license
fmriprep \
    /data \
    /output \
    participant \
    --work-dir /workdir \
    --skip_bids_validation \
    --participant-label ${SUBJECT_ID} \
    --nthreads ${NTHREAD} \
    --omp-nthreads ${NTHREAD} \
    --anat-only
EOT

export SINGULARITYENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

export SKIP_REPORT=1
source ./sbatch/post_run.sh

# Extra cleanup
mkdir -p ${SLURM_TMPDIR}/derivatives/fmriprep/anat-fs/sub-${SUBJECT_ID}
rsync -aLq --info=progress2 \
    ${SUBJECT_OUTPUT}/ \
    ${SLURM_TMPDIR}/derivatives/fmriprep/anat-fs/sub-${SUBJECT_ID}/
rm -rf ${SUBJECT_OUTPUT}
rm -rf ${WORK_DIR}

