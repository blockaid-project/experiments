#!/usr/bin/env bash
rounds=${1:?please provide rounds}
output_dir=${2:?please provide output dir}

if grep -q 'enable_caching=true' "$HOME/diaspora/.rbenv-vars"; then
  echo "Caching is enabled; can't measure no-cache"
  exit 1
fi

for i in `seq 1 5`; do
  ~/start_diaspora.sh production_mod_checked &
  sleep 40
  numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "no-cache$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/no-cache$i.csv"
done

sudo shutdown -h now
