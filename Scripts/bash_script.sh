#!/usr/bin/env bash
set -euo pipefail

# Paths
FLAMEGRAPH_DIR="$HOME/FlameGraph"   # Update if FlameGraph is installed elsewhere
ORJSON_SCRIPT="./orjson_pyperf_bench.py"

# Check FlameGraph tools
if [[ ! -x "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" || ! -x "$FLAMEGRAPH_DIR/flamegraph.pl" ]]; then
  echo "Error: FlameGraph tools not found in $FLAMEGRAPH_DIR"
  echo "Clone from https://github.com/brendangregg/FlameGraph and update FLAMEGRAPH_DIR."
  exit 1
fi

# --- Run stdlib json benchmark ---
echo "[*] Running stdlib json_dumps benchmark..."
perf record -F 999 -g -o perf.json.data -- \
  python3-dbg -m pyperformance run --bench json_dumps

echo "[*] Generating flamegraph for json_dumps..."
perf script -i perf.json.data > out.json.perf
"$FLAMEGRAPH_DIR/stackcollapse-perf.pl" out.json.perf > out.json.folded
"$FLAMEGRAPH_DIR/flamegraph.pl" out.json.folded > flamegraph_json.svg

# --- Run orjson benchmark ---
echo "[*] Running orjson benchmark..."
perf record -F 999 -g -o perf.orjson.data -- \
  python3-dbg "$ORJSON_SCRIPT" --values 40 --warmups 3 --affinity 0 -o orjson_dbg.json

echo "[*] Generating flamegraph for orjson..."
perf script -i perf.orjson.data > out.orjson.perf
"$FLAMEGRAPH_DIR/stackcollapse-perf.pl" out.orjson.perf > out.orjson.folded
"$FLAMEGRAPH_DIR/flamegraph.pl" out.orjson.folded > flamegraph_orjson.svg

echo "[*] Done."
echo "Generated flamegraphs:"
echo "  - flamegraph_json.svg"
echo "  - flamegraph_orjson.svg"
