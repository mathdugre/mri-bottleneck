#!/bin/bash

#SBATCH -J fsl-mcflirt
#SBATCH --array=1
#SBATCH --time=4:00:00
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
source ./sbatch/pre_run.sh fsl mcflirt -j ${SLURM_CPUS_PER_TASK} $@

cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
source /fsl_env.sh
mkdir -p /data/derivatives/fsl/mcflirt/sub-${SUBJECT_ID}/ses-1/func/
mcflirt \
    -o /data/derivatives/fsl/mcflirt/sub-${SUBJECT_ID}/ses-1/func/sub-${SUBJECT_ID}_ses-1_task-rest_run-1_bold_mcf.nii.gz \
    /data/sub-${SUBJECT_ID}/ses-1/func/sub-${SUBJECT_ID}_ses-1_task-rest_run-1_bold.nii.gz
EOT

export SINGULARITYENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
