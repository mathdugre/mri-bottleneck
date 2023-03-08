DATASET=/mnt/lustre/mathdugre/datasets/CoRR/LMU_2
OUTPUT=/mnt/lustre/mathdugre/mri-bottleneck
SIF_IMG=$HOME/containers/ants-debug.sif

N_SUBJECTS=$(awk 'END {print NR-1}' $DATASET/participants.tsv)

for f in $(find sbatch/* -mindepth 1 -name "*.sh")
do
    echo sbatch --array=1-${N_SUBJECTS} $f $SIF_IMG -i $DATASET -o $OUTPUT
done