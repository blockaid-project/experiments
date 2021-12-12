#!/usr/bin/env bash
rounds=${1:?please provide rounds}
output_dir=${2:?please provide output dir}
output_dir=$(readlink -f "$output_dir")

exec > >(tee -ia "$output_dir/run.stdout.log")
exec 2> >(tee -ia "$output_dir/run.stderr.log")

# Cache enabled.
cp common/cache.rbenv-vars ~/diaspora/.rbenv-vars

~/start_diaspora.sh production_mod_checked &
sleep 40
numactl -N 1 -m 1 python3 diaspora/measure_fetch.py "cached" --warmup-rounds 1 --measure-rounds 0
numactl -N 1 -m 1 python3 diaspora/measure_plt.py "cached" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/cached.csv"

~/start_diaspora.sh production_mod &
sleep 40
numactl -N 1 -m 1 python3 diaspora/measure_plt.py "modified" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/modified.csv"

~/start_diaspora.sh production &
sleep 40
numactl -N 1 -m 1 python3 diaspora/measure_plt.py "original" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/original.csv"

# # Cache disabled.
# cp common/no-cache.rbenv-vars ~/diaspora/.rbenv-vars
# ~/start_diaspora.sh production_mod_checked &
# sleep 40
# numactl -N 1 -m 1 python3 diaspora/measure_plt.py "no-cache" --warmup-rounds "$rounds" --measure-rounds "$rounds" >> "$output_dir/no-cache.csv"

# sudo shutdown -h now

