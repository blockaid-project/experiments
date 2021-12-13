#!/usr/bin/env bash
output_dir=${1:?please provide output dir}
output_dir=$(readlink -f "$output_dir")

exec > >(tee -ia "$output_dir/run.stdout.log")
exec 2> >(tee -ia "$output_dir/run.stderr.log")

# Cache enabled.
# cp common/cache.rbenv-vars ~/spree/sandbox/.rbenv-vars
# 
# ~/start_spree.sh production_mod_checked &
# sleep 60
# numactl -N 1 -m 1 python3 spree/measure_fetch.py "cached" --warmup-rounds 1 --measure-rounds 0
# numactl -N 1 -m 1 python3 spree/measure_plt.py "cached" --warmup-rounds 3000 --measure-rounds 3000 >> "$output_dir/cached.csv"
# 
# ~/start_spree.sh production_mod &
# sleep 60
# numactl -N 1 -m 1 python3 spree/measure_plt.py "modified" --warmup-rounds 3000 --measure-rounds 3000 >> "$output_dir/modified.csv"
# 
# ~/start_spree.sh production &
# sleep 60
# numactl -N 1 -m 1 python3 spree/measure_plt.py "original" --warmup-rounds 3000 --measure-rounds 3000 >> "$output_dir/original.csv"

# Cache disabled.
cp common/no-cache.rbenv-vars ~/spree/sandbox/.rbenv-vars
~/start_spree.sh production_mod_checked &
sleep 60
numactl -N 1 -m 1 python3 spree/measure_plt.py "no-cache" --warmup-rounds 100 --measure-rounds 100 >> "$output_dir/no-cache.csv"

# sudo shutdown -h now

