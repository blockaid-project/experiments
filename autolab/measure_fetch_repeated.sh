#!/usr/bin/env bash
for i in `seq 1 10`; do
    ssh autolab.internal "./start_server.sh production" &
    sleep 20
    python3 autolab/measure_fetch.py "baseline_$i" --warmup-rounds 1000 --measure-rounds 500 > "$HOME/nsdi-runs/sep-23/autolab/fetch/baseline_$i.csv"
done

