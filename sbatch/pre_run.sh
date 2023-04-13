#!/bin/bash
set -e
set -u

TOOLKIT=$1; shift
FUNC=$1; shift
USAGE="
Usage: sh ${TOOLKIT} ${FUNC} <SIF_IMG> -i <DATA_DIR> -o <PROJECT_DIR> [-j <NTHREAD>]

    SIF_IMG: Path to the Singularity image to profile.

    OPTIONS:

    -h: print this help message.

    -i DATA_DIR: Path to the input data directory.

    -j NTHREAD: Number of threads used for the application. By default use all.

    -o PROJECT_DIR: Path to the project directory.
"

# Initalize env loading on either Slashbin and Compute Canada
[[ -z ${SLURM_TMPDIR:+x} ]] && export SLURM_TMPDIR=/disk5/${USER}/mri-bottleneck

if command -v module &>/dev/null
then 
    module is-availl singularity && module load singularity
    module is-availl python/3.10 && mdoule load python/3.10
fi
if ! command -v singularity &>/dev/null
then
    echo "[ERROR] singularity: command not found."
    exit 127
fi
if ! command -v python &>/dev/null
then
    echo "[ERROR] python: command not found."
    exit 127
fi

# Parse arguments
function validate_opt(){
    if [ -z ${2:+x} ] || [ ${2:0:1} == "-" ]; then
        echo "Error: Argument for $1 is missing" >&2
        echo "${USAGE}"
        exit 1
    fi
}

# Default parameters
NTHREAD=$(nproc)

PARAMS=""
while (( $# )); do
  case $1 in
    -h | --help)
      echo "${USAGE}" && exit 0;;
    -i | --input )
        validate_opt $@
        DATA_DIR=$2
        shift 2;;
    -j | --nthread)
        validate_opt $@
        NTHREAD=$(($2>NTHREAD ? NTRHEAD : $2))
        shift 2;;
    -o | --output)
        validate_opt $@
        PROJECT_DIR=$2
        shift 2;;
    -* | --*=) # unsupported flags
      echo "Error: Unsupported flag ${1}" >&2
      exit 1
      ;;
    * ) # preserve positional arguments
      PARAMS="${PARAMS} $1"
      shift
      ;;
  esac
done
eval set -- ${PARAMS}

# Ensure singularity image is passed.
if [[ -z ${1:+x} ]]; then
    echo "ERROR: missing argument: SIF_IMG"
    echo "${USAGE}"
    exit 1
fi
SIF_IMG=$1
if [[ ! -f ${SIF_IMG} ]]; then
    echo "Error: SIF_IMG path does not exist: ${SIF_IMG} "
    exit 1
fi

# Validate arguments
if [[ -z ${DATA_DIR} || -z  ${PROJECT_DIR}  || -z ${SIF_IMG} ]]; then
    echo "${USAGE}"
    exit 1
fi
if [[ ! -d ${DATA_DIR} ]]; then
    echo "Error: DATA_DIR direcotry does not exist: ${DATA_DIR} "
    exit 1
fi

# Set variables for external use.
mkdir -p ${PROJECT_DIR}
export SIF_IMG
export DATA_DIR
export NTHREAD
export DATASET=$(basename ${DATA_DIR})
export OUTPUT_DIR=${PROJECT_DIR}/${TOOLKIT}/${FUNC}/${DATASET}


[[ -z ${SLURM_ARRAY_TASK_ID:+x} ]] && SLURM_ARRAY_TASK_ID=1
export SUBJECT_ID=$(sed -n $(( 1 + ${SLURM_ARRAY_TASK_ID} ))p ${DATA_DIR}/participants.tsv | cut -f1)

export RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
export PROFILING_DIR=${PROJECT_DIR}/"vtune_output"/${TOOLKIT}/${FUNC}/${DATASET}/sub-${SUBJECT_ID}/${RANDOM_STRING}
mkdir -p ${PROFILING_DIR}

echo "---------------------
Profiling information

Pipeline: ${TOOLKIT} ${FUNC}
NTHREAD: ${NTHREAD}

DATASET: ${DATASET}
SUBJECT_ID: ${SUBJECT_ID}

SIF_IMG: ${SIF_IMG}
DATA_DIR: ${DATA_DIR}
OUTPUT_DIR: ${OUTPUT_DIR}

PROJECT_DIR: ${PROJECT_DIR}
PROFILING_DIR: ${PROFILING_DIR}
---------------------
"

# Transfer dataset to compute node.
rm -rf ${SLURM_TMPDIR}
mkdir -p ${SLURM_TMPDIR}/input/sub-${SUBJECT_ID}
rsync -aLq --info=progress2 \
    ${DATA_DIR}/sub-${SUBJECT_ID}/ \
    ${SLURM_TMPDIR}/input/sub-${SUBJECT_ID}/

# Create temp directory for pipeline scripts.
export TMP_SCRIPT=tmp-scripts
mkdir -p ${TMP_SCRIPT}
