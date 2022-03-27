#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 env diaspora_path log_file_path" >&2
    exit 2
fi

env=${1:?please provide env}
diaspora_path=${2:?please provide path to diaspora}
log_file_path=${3:?please provide path to output log file}

killall java || true
cd "$diaspora_path" || { echo "diaspora path not found: $diaspora_path"; exit 1; }
rm -f shared/log/puma.std*

case "$env" in
  production | production_mod | production_mod_checked)
    branch="main"
    ;;

  *)
    echo "Unknown env: $env"
    exit 1
    ;;
esac

git checkout "$branch"
RAILS_ENV=$env numactl -N 0 -m 0 bundle exec rails server puma > "$log_file_path" 2>&1
