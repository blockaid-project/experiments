#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Update Blockaid.
(cd "$HOME/privacy_proxy"; git pull --ff-only; mvn compile assembly:single)

apps=(diaspora spree autolab)
kinds=(plt fetch)

if [[ -z "${TEST_RUN}" ]]
then
  env="TEST_RUN=1"
else
  env=""
fi

tmux_config=()

num_left=$(( ${#apps[@]} * ${#kinds[@]} ))
curr=1
for measure_kind in "${kinds[@]}"
do
  for app_name in "${apps[@]}"
  do
    tmux_config+=("send-keys '$env $SCRIPT_DIR/run_ae_remote.sh $curr $measure_kind $app_name'")
    percentage=$(( (num_left - 1) / num_left ))
    tmux_config+=("split-window -v -p $percentage")
    curr=$((curr+1))
    num_left=$((num_left-1))
  done
done

# TODO(zhangwen): shut down instances.
