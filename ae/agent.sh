#!/usr/bin/env bash
set -e

source "$HOME/.profile"
workon experiment

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
"$SCRIPT_DIR/../run_experiment.sh" "$@"
