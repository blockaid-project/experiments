#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_DIR="$HOME/ae_data"

# Update Blockaid.
(cd "$HOME/privacy_proxy"; git pull --ff-only; mvn compile assembly:single)

# Assumes EC2 user data is a text file where each line has the form "kind app".
curl http://169.254.169.254/latest/user-data | while IFS= read -r line; do
  line_array=("$line")
  kind="${line_array[0]}"
  app="${line_array[1]}"
  "$SCRIPT_DIR/run_experiment.sh" "$kind" "$app" "$OUTPUT_DIR"
done
