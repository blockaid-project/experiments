#!/usr/bin/env bash
output_dir=${1:?please provide output dir}
output_dir=$(readlink -f $output_dir)

exec > >(tee -ia "$output_dir/run.stdout.log")
exec 2> >(tee -ia "$output_dir/run.stderr.log")

for i in `seq 1 1`; do
  # Cache enabled.
  cp common/cache.rbenv-vars ~/Autolab/.rbenv-vars

  ~/start_server.sh production_mod_checked &
  sleep 30
  # python3 autolab/measure_fetch.py "populate" --warmup-rounds 1 --measure-rounds 0
  # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  numactl -N 1 -m 1 python3 autolab/measure_fetch.py "cached$i" --warmup-rounds 3000 --measure-rounds 3000 >> "$output_dir/cached$i.csv"

  # ~/start_server.sh production_mod &
  # sleep 30
  # # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  # numactl -N 1 -m 1 python3 autolab/measure_fetch.py "modified$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/modified$i.csv"

  # ~/start_server.sh production &
  # sleep 30
  # # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  # numactl -N 1 -m 1 python3 autolab/measure_fetch.py "original$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/original$i.csv"

  # # Cache disabled.
  # cp common/no-cache.rbenv-vars ~/Autolab/.rbenv-vars
  # ~/start_server.sh production_mod_checked &
  # sleep 30
  # numactl -N 1 -m 1 python3 autolab/measure_fetch.py "no-cache$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/no-cache$i.csv"

  # Cold cache.
  cp common/cold-cache.rbenv-vars ~/Autolab/.rbenv-vars
  ~/start_server.sh production_mod_checked &
  sleep 30
  numactl -N 1 -m 1 python3 autolab/measure_fetch.py "cold-cache$i" --warmup-rounds 100 --measure-rounds 100 >> "$output_dir/cold-cache$i.csv"
  killall java
  (cd ~/scratch; tar -czvf "$output_dir/cold-cache$i-log.tar.gz" puma.log)
done

# sudo shutdown -h now
