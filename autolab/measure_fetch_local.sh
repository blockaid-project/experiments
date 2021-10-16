#!/usr/bin/env bash
rounds=${1:?please provide rounds}
output_dir=${2:?please provide output dir}

for i in `seq 1 5`; do
  ~/start_server.sh production_mod_checked &
  sleep 30
  # python3 autolab/measure_fetch.py "populate" --warmup-rounds 1 --measure-rounds 0
  # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  numactl -N 1 -m 1 python3 autolab/measure_fetch.py "cached$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/cached$i.csv"
  
  ~/start_server.sh production_mod &
  sleep 30
  # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  numactl -N 1 -m 1 python3 autolab/measure_fetch.py "modified$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/modified$i.csv"

  ~/start_server.sh production &
  sleep 30
  # wrk -t8 -c8 -d30m -s autolab/fetch.lua https://autolab.internal/
  numactl -N 1 -m 1 python3 autolab/measure_fetch.py "original$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/original$i.csv"
done

sudo shutdown -h now
