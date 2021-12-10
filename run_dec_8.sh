#!/usr/bin/env bash
rounds=${1:?please provide rounds}

bash ./diaspora/measure_fetch_local.sh "$rounds" ~/data/dec-8/diaspora
bash ./autolab/measure_fetch_local.sh "$rounds" ~/data/dec-8/autolab
bash ./spree/measure_fetch_local.sh "$rounds" ~/data/dec-8/spree

# sudo shutdown -h now
