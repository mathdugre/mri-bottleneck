#!/bin/bash

#SBATCH -J ants-registrationSyN-fp
#SBATCH --array=1
#SBATCH --time=8:00:00
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
source ./sbatch/pre_run.sh ants registrationSyN-fp -j ${SLURM_CPUS_PER_TASK} $@

export SIF_OPTION="-B $HOME/.cache/templateflow:/templateflow"
cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
TMPLT="/templateflow/tpl-MNI152NLin2009cAsym/"

antsRegistrationSyN.sh \
    -d 3 \
    -f \${TMPLT}/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz\
    -m /data/derivatives/fsl/fast/sub-${SUBJECT_ID}/ses-open/anat/BrainExtractionBrain_seg.nii.gz \
    -o /data/derivatives/ants/registrationSyN-fp/sub-${SUBJECT_ID}/ses-open/anat/ \
    -p f
EOT

export APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
