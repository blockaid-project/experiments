#!/usr/bin/env bash
rounds=${1:?please provide rounds}
output_dir=${2:?please provide output dir}

for i in `seq 1 5`; do
  ~/start_diaspora.sh production_mod_checked &
  sleep 40
  numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "cached$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/cached$i.csv"
  
  ~/start_diaspora.sh production_mod &
  sleep 40
  numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "modified$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/modified$i.csv"

  ~/start_diaspora.sh production &
  sleep 40
  numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "original$i" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/original$i.csv"
done

sudo shutdown -h now
