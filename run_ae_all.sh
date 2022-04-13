#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TMUX_CONF="/tmp/tmux.ae.conf"

# Update Blockaid.
if [[ -z "${SKIP_PULL}" ]]
then
  (cd "$HOME/privacy_proxy"; git pull --ff-only; mvn compile assembly:single)
fi

apps=(diaspora spree autolab)
kinds=(plt fetch)

if [[ -z "${TEST_RUN}" ]]
then
  env=""
else
  env="TEST_RUN=1"
fi

tmux_config=()

num_left=$(( ${#apps[@]} * ${#kinds[@]} ))
curr=0
for measure_kind in "${kinds[@]}"
do
  for app_name in "${apps[@]}"
  do
    tmux_config+=("send-keys '$env $SCRIPT_DIR/ae/launch_remote.sh $curr $measure_kind $app_name' C-m")
    if [[ "$num_left" -ne 1 ]]
    then
      percentage=$(( 100 * (num_left - 1) / num_left ))
      tmux_config+=("split-window -v -p $percentage")
    fi
    curr=$((curr+1))
    num_left=$((num_left-1))
  done
done

(IFS=$'\n'; echo "${tmux_config[*]}" > "$TMUX_CONF")

tmux new-session \; source-file "$TMUX_CONF" \;

# TODO(zhangwen): shut down instances.
