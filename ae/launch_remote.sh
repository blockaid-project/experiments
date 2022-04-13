#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 idx kind app" >&2
    exit 2
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_DIR="$HOME/ae_data"

AGGREGATE_DIR="$HOME/ae_aggregate"

idx="$1"
measure_kind="$2"
app_name="$3"

if [[ -z "${TEST_RUN}" ]]
then
  env=""
else
  env="export TEST_RUN=1;"
fi

ip="10.10.1.$idx"
ssh -o StrictHostKeyChecking=no "$ip" "$env $SCRIPT_DIR/agent.sh $measure_kind $app_name $OUTPUT_DIR"

mkdir -p "$AGGREGATE_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -r "$ip:$OUTPUT_DIR/" "$AGGREGATE_DIR/"
