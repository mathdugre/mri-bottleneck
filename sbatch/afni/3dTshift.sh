#!/bin/bash

#SBATCH -J afni-3dTshift
#SBATCH --array=1
#SBATCH --time=24:00:00
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=0
# -------------------------
#SBATCH -o log/%x-%A-%a.out
#SBATCH -e log/%x-%A-%a.err
# -------------------------
set -e
set -u

# Setup environment and parse args.
source ./sbatch/pre_run.sh afni 3dTshift -j ${SLURM_CPUS_PER_TASK} $@

cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
3dTshift \
    -tzero 0 \
    -quintic \
    /data/sub-${SUBJECT_ID}/ses-open/func/sub-${SUBJECT_ID}_ses-open_task-rest_bold.nii.gz
EOT

export SINGULARITYENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
