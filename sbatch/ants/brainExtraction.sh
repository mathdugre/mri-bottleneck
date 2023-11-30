#!/bin/bash

#SBATCH -J ants-brainExtraction
#SBATCH --array=1
#SBATCH --time=2:00:00
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

cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
TMPLT="/opt/templates/OASIS"

antsBrainExtraction.sh \
    -d 3 \
    -a /data/sub-${SUBJECT_ID}/ses-open/anat/sub-${SUBJECT_ID}_ses-open_T1w.nii.gz \
    -e \${TMPLT}/T_template0.nii.gz \
    -m \${TMPLT}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -o /data/derivatives/ants/brainExtraction/sub-${SUBJECT_ID}/ses-open/anat/
EOT

export APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
