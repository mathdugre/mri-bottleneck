#!/bin/bash

#SBATCH -J fsl-flirt
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
source ./sbatch/pre_run.sh fsl flirt -j ${SLURM_CPUS_PER_TASK} $@

export SIF_OPTION="-B $HOME/.cache/templateflow:/templateflow"
cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
source /fsl_env.sh
TMPLT="/templateflow/tpl-MNI152NLin2009cAsym/"
mkdir -p /data/derivatives/fsl/flirt/sub-${SUBJECT_ID}/ses-1/anat/

flirt \
    -in /data/sub-${SUBJECT_ID}/ses-1/anat/sub-${SUBJECT_ID}_ses-1_run-1_T1w.nii.gz \
    -ref \${TMPLT}/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz \
    -out /data/sub-${SUBJECT_ID}/ses-1/anat/sub-${SUBJECT_ID}_ses-1_run-1_T1w_flirt.nii.gz
EOT

export SINGULARITYENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
