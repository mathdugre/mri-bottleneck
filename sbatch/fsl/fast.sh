#!/bin/bash

#SBATCH -J fsl-fast
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
source ./sbatch/pre_run.sh fsl fast -j ${SLURM_CPUS_PER_TASK} $@

cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
source /fsl_env.sh
mkdir -p /data/derivatives/fsl/fast/sub-${SUBJECT_ID}/ses-open/anat/
fast \
    -o /data/derivatives/fsl/fast/sub-${SUBJECT_ID}/ses-open/anat/BrainExtractionBrain \
    /data/derivatives/ants/brainExtraction/sub-${SUBJECT_ID}/ses-open/anat/BrainExtractionBrain.nii.gz
EOT

export APPTAINERENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
