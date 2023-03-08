#!/bin/bash
set -e
set -u

FUNC=$1; shift
USAGE="
Usage: sh ${FUNC} <SIF_IMG> -i <INPUT_DIR> -o <OUTPUT_DIR> [-j <NTHREAD>]

    SIF_IMG: Path to the Singularity image to profile.

    OPTIONS:

    -h: print this help message.

    -i INPUT_DIR: Root of the input dataset.

    -j NTHREAD: Number of threads used for the application. By default use all.

    -o OUTPUT_DIR: Path to the output directory.
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

NTHREAD=$(nproc)
PROFILING_DIR="vtune_output"

PARAMS=""
while (( $# )); do
  case $1 in
    -h | --help)
      echo "${USAGE}" && exit 0;;
    -i | --input )
        validate_opt $@
        INPUT_DIR=$2
        shift 2;;
    -j | --nthread)
        validate_opt $@
        NTHREAD=$(($2>NTHREAD ? NTRHEAD : $2))
        shift 2;;
    -o | --output)
        validate_opt $@
        OUTPUT_DIR=$2
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
SIF_IMG=$1

# Validate arguments
if [[ -z ${INPUT_DIR} || -z  ${OUTPUT_DIR}  || -z ${SIF_IMG} ]]; then
    echo "${USAGE}"
    exit 1
fi
if [[ ! -d ${INPUT_DIR} ]]; then
    echo "Error: INPUT_DIR direcotry does not exist: ${INPUT_DIR} "
    exit 1
fi
if [[ ! -f ${SIF_IMG} ]]; then
    echo "Error: SIF_IMG path does not exist: ${SIF_IMG} "
    exit 1
fi

export SIF_IMG
export INPUT_DIR
export OUTPUT_DIR
export NTHREAD
export DATASET=$(basename ${INPUT_DIR})
export SUBJECT_ID=$(sed -n $(( 1 + ${SLURM_ARRAY_TASK_ID} ))p ${INPUT_DIR}/participants.tsv | cut -f1)

echo "---------------------
Profiling information

Pipeline: ${FUNC}
SIF_IMG: ${SIF_IMG}
INPUT_DIR: ${INPUT_DIR}
OUTPUT_DIR: ${OUTPUT_DIR}
NTHREAD: ${NTHREAD}
DATASET: ${DATASET}
SUBJECT_ID: ${SUBJECT_ID}
---------------------
"