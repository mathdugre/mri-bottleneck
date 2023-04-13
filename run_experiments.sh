LFS_HOME=/mnt/lustre/mathdugre
DATASET=LMU_2
SIF_DIR=$HOME/containers

N_SUBJECTS=$(awk 'END {print NR-1}' ${LFS_HOME}/datasets/CoRR/${DATASET}/participants.tsv)

echo sbatch --array=1-${N_SUBJECTS} sbatch/ants/brainExtraction.sh $SIF_DIR/ants-debug.sif -i ${LFS_HOME}/datasets/CoRR/${DATASET} -o ${LFS_HOME}/mri-bottleneck
echo sbatch --array=1-${N_SUBJECTS} sbatch/ants/brainExtraction-fp.sh $SIF_DIR/ants-debug.sif -i ${LFS_HOME}/datasets/CoRR/${DATASET} -o ${LFS_HOME}/mri-bottleneck

echo sbatch --array=1-${N_SUBJECTS} sbatch/fsl/fast.sh $SIF_DIR/fsl-debug.sif -i ${LFS_HOME}/mri-bottleneck/ants/brainExtraction/${DATASET} -o ${LFS_HOME}/mri-bottleneck