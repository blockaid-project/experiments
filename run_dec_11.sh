#!/usr/bin/env bash
rounds=${1:?please provide rounds}

bash ./diaspora/measure_fetch_local.sh "$rounds" ~/data/dec-11-plt/diaspora
bash ./autolab/measure_fetch_local.sh "$rounds" ~/data/dec-11-plt/autolab
bash ./spree/measure_fetch_local.sh "$rounds" ~/data/dec-11-plt/spree

