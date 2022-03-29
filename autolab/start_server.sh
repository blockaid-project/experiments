#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 env autolab_path log_file_path" >&2
    exit 2
fi

env=${1:?please provide env}
autolab_path=${2:?please provide path to Autolab}
log_file_path=${3:?please provide path to output log file}

killall java || true
cd "$autolab_path" || { echo "Autolab path not found: $autolab_path"; exit 1; }
rm -f log/*.log*
rm -f shared/log/puma.std*

case "$env" in
  production)
    branch="bv2.7.0-orig"
    ;;

  production_mod | production_mod_checked)
    branch="bv2.7.0"
    ;;

  *)
    echo "Unknown env: $env"
    exit 1
    ;;
esac

git checkout "$branch"
RAILS_ENV=$env numactl -N 0 -m 0 bundle exec rails server puma > "$log_file_path" 2>&1
