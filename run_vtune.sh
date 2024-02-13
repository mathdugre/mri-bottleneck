#!/bin/bash
set -e
set -u

if [[ -z ${1:+x} ]]; then
    echo "ERROR: Missing argument: Path to VTune output."
    exit 1
fi

source $HOME/intel/oneapi/setvars.sh --force
vtune-backend --web-port 8080 --allow-remote-access --data-directory $1 --reset-passphrase
