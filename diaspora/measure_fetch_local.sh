#!/usr/bin/env bash
rounds=${1:?please provide rounds}
output_dir=${2:?please provide output dir}
output_dir=$(readlink -f $output_dir)

exec > >(tee -ia "$output_dir/run.stdout.log")
exec 2> >(tee -ia "$output_dir/run.stderr.log")

for i in `seq 1 1`; do
  # # Cache enabled.
  # cp common/cache.rbenv-vars ~/diaspora/.rbenv-vars

  # ~/start_diaspora.sh production_mod_checked &
  # sleep 40
  # numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "cached$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/cached$i.csv"
  # 
  # ~/start_diaspora.sh production_mod &
  # sleep 40
  # numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "modified$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/modified$i.csv"

  # ~/start_diaspora.sh production &
  # sleep 40
  # numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "original$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/original$i.csv"

  # # Cache disabled.
  # cp common/no-cache.rbenv-vars ~/diaspora/.rbenv-vars
  # ~/start_diaspora.sh production_mod_checked &
  # sleep 40
  # numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "no-cache$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/no-cache$i.csv"

  # Cold cache.
  cp common/cold-cache.rbenv-vars ~/diaspora/.rbenv-vars
  ~/start_diaspora.sh production_mod_checked &
  sleep 40
  numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "cold-cache$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/cold-cache$i.csv"
  killall java
  (cd ~/scratch; tar -czvf "$output_dir/cold-cache$i-log.tar.gz" puma.log)
done

# sudo shutdown -h now