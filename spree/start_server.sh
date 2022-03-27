#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 env spree_path log_file_path" >&2
    exit 2
fi

env=${1:?please provide env}
spree_path=${2:?please provide path to Spree}
log_file_path=${3:?please provide path to output log file}

killall java || true
cd "$spree_path" || { echo "Spree path not found: $spree_path"; exit 1; }
cd sandbox || { echo "Spree sandbox path not found: $spree_path/sandbox"; exit 1; }
rm -f shared/log/puma.std*

case "$env" in
  production)
    branch="bv4.3.0-orig"
    ;;

  production_mod | production_mod_checked)
    branch="bv4.3.0"
    ;;

  *)
    echo "Unknown env: $env"
    exit 1
    ;;
esac

git checkout "$branch"
bundle install >/dev/null
RAILS_ENV=$env numactl -N 0 -m 0 bundle exec rails server > "$log_file_path" 2>&1
