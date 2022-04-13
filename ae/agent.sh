#!/usr/bin/env bash
set -e

args=("$@")

source "$HOME/.profile"
workon experiments

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
"$SCRIPT_DIR/../run_experiment.sh" "${args[@]}"
