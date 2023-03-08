#!/bin/bash

#SBATCH -J ants-BrainExtraction
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
source ./sbatch/pre_run.sh ants brainExtraction -j ${SLURM_CPUS_PER_TASK} $@

TMPLT="/opt/templates/OASIS"
export SINGULARITYENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREAD
vtune.sh antsBrainExtraction.sh \
    -d 3 \
    -a /data/input/sub-${SUBJECT_ID}/ses-1/anat/sub-${SUBJECT_ID}_ses-1_run-1_T1w.nii.gz \
    -e ${TMPLT}/T_template0.nii.gz \
    -m ${TMPLT}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -o /data/output/${DATASET}/sub-${SUBJECT_ID}

source ./sbatch/post_run.sh

