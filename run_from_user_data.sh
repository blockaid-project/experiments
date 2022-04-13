#!/usr/bin/env bash
output_dir=${1:?please provide output dir}

# Expect user data to have the form "measure_kind app_name".
user_data=$(curl -s http://169.254.169.254/latest/user-data)
IFS=' ' read -r -a user_data_array <<< "$user_data"
measure_kind="${user_data_array[0]}"
app_name="${user_data_array[1]}"

source "$HOME/.profile"
workon experiments

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
"$SCRIPT_DIR/run_experiment.sh" "$measure_kind" "$app_name" "$output_dir"
