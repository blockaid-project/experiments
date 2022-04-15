#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 kind app output_dir" >&2
    exit 2
fi

CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

experiment_output_dir="$3"

declare -A app2path=( ["diaspora"]="$HOME/diaspora" ["spree"]="$HOME/spree" ["autolab"]="$HOME/Autolab" )

declare -A kind2tags=(
  ["plt"]="original modified cached no-cache"
  ["fetch"]="original modified cached cold-cache no-cache"
)

measure_kind="$1"
app_name="$2"

if ! [[ -v "app2path[$app_name]" ]]
then
  echo "unrecognized app: $app_name"
  exit 1
fi

if ! [[ -v "kind2tags[$measure_kind]" ]]
then
  echo "unrecognized kind: $measure_kind"
  exit 1
fi

declare -A tag2env=(
  ["original"]="production" ["modified"]="production_mod"
  ["cached"]="production_mod_checked" ["no-cache"]="production_mod_checked" ["cold-cache"]="production_mod_checked"
)

declare -A tag2cacheConfig=(
  ["original"]="cache" ["modified"]="cache"  # These two are run without Blockaid, so cache config doesn't matter.
  ["cached"]="cache" ["no-cache"]="no-cache" ["cold-cache"]="cold-cache"
)

: "${RUN_MODE:?Must provide run mode}"
declare -A tag2rounds
case $RUN_MODE in

  test)
    tag2rounds=(["original"]=3 ["modified"]=3 ["cached"]=3 ["no-cache"]=3 ["cold-cache"]=3)
    ;;

  small)
    tag2rounds=(["original"]=300 ["modified"]=300 ["cached"]=300 ["no-cache"]=10 ["cold-cache"]=10)
    ;;

  full)
    tag2rounds=(["original"]=3000 ["modified"]=3000 ["cached"]=3000 ["no-cache"]=100 ["cold-cache"]=100)
    ;;

  *)
    echo "FATAL: Unrecognized run mode: $RUN_MODE"
    exit 1
    ;;

esac

app_path="${app2path[$app_name]}"
IFS=" " read -r -a tags <<< "${kind2tags[$measure_kind]}"
for tag in "${tags[@]}"
do
  env="${tag2env[$tag]}"
  cache_config="${tag2cacheConfig[$tag]}"
  rounds="${tag2rounds[$tag]}"
  output_dir="$experiment_output_dir/$measure_kind/$app_name/$tag"

  echo -e "${CYAN}[$measure_kind, $app_name, $tag, rounds=$rounds] starting...${NC}"

  (
    mkdir -p "$output_dir"
    if [ -f "$output_dir/data.csv" ]; then
        echo "data already found in $output_dir; skipping this experiment..."
        exit 0
    fi

    exec > >(tee -i "$output_dir/stdout.log")
    exec 2> >(tee -i "$output_dir/stderr.log")

    cache_config_path="$SCRIPT_DIR/common/$cache_config.rbenv-vars"
    cp "$cache_config_path" "$app_path/.rbenv-vars"

    experiment_config_path="$SCRIPT_DIR/$app_name"
    if [ ! -d "$experiment_config_path" ]; then
      echo "cannot find experiment config path: $experiment_config_path"
      exit 1
    fi

    "$experiment_config_path/start_server.sh" "$env" "$app_path" "$output_dir/server.log" &
    numactl -N 1 -m 1 "$SCRIPT_DIR/measure_latency.py" "$measure_kind" "$tag" "$experiment_config_path/tests.yaml" \
        --warmup-rounds="$rounds" --measure-rounds="$rounds" > "$output_dir/data.csv.tmp" \
      || { cat "$output_dir/server.log"; exit 1; }

    killall java || true
    (tar -czvf "$output_dir/server_log.tar.gz" -C "$output_dir" server.log --remove-files)
    mv "$output_dir/data.csv.tmp" "$output_dir/data.csv"
  )
done
