#!/bin/bash

#SBATCH -J freesurfer-reconall
#SBATCH --array=1
#SBATCH --time=24:00:00
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
source ./sbatch/pre_run.sh freesurfer reconall -j ${SLURM_CPUS_PER_TASK} $@

export SIF_OPTION="-B $HOME/.freesurfer.txt:/opt/freesurfer/.license"
cat <<EOT >> ${TMP_SCRIPT}/${RANDOM_STRING}.sh
set -e

mkdir -p /data/derivatives/freesurfer/reconall

# Step 1
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -i /data/sub-${SUBJECT_ID}/ses-1/anat/sub-${SUBJECT_ID}_ses-1_run-1_T1w.nii.gz \
    -autorecon1 \
    -noskullstrip -noT2pial -noFLAIRpial \
    -threads ${NTHREAD}

# Step 2
python3 ./sbatch/freesurfer/skull_strip_extern.py \
    /data/derivatives/freesurfer/reconall/sub-${SUBJECT_ID}/mri \
    /data/derivatives/ants/brainExtraction/sub-${SUBJECT_ID}/ses-1/anat/BrainExtractionBrain.nii.gz

# Step 3
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -gcareg \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon2-volonly \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon-hemi lh \
    -noparcstats -noparcstats2 -noparcstats3 -nohyporelabel -nobalabels \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon-hemi rh \
    -noparcstats -noparcstats2 -noparcstats3 -nohyporelabel -nobalabels \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -cortribbon \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon-hemi lh -nohyporelabel \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon-hemi rh -nohyporelabel \
    -threads ${NTHREAD}
recon-all \
    -sd /data/derivatives/freesurfer/reconall \
    -subjid sub-${SUBJECT_ID} \
    -autorecon3 \
    -threads ${NTHREAD}
EOT

export SINGULARITYENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREAD
export SINGULARITYENV_OMP_NUM_THREADS=$NTHREAD
source ./sbatch/vtune.sh bash ${TMP_SCRIPT}/${RANDOM_STRING}.sh

source ./sbatch/post_run.sh
