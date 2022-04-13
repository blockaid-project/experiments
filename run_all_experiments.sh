#!/usr/bin/env bash
set -e

experiment_output_dir=${1:?please provide output directory for this experiment}

apps=(diaspora spree autolab)
kinds=(plt fetch)

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
for measure_kind in "${kinds[@]}"
do
  for app_name in "${apps[@]}"
  do
    "$SCRIPT_DIR/run_experiment.sh" "$measure_kind" "$app_name" "$experiment_output_dir"
  done
done
