#!/usr/bin/env bash
set -e

args=("$@")

source "$HOME/.profile"
workon experiments

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

(cd "$HOME/privacy_proxy"; git pull --ff-only; mvn compile assembly:single)
(cd "$SCRIPT_DIR")

"$SCRIPT_DIR/../run_experiment.sh" "${args[@]}"
