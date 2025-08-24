#!/usr/bin/env bash
set -euo pipefail
REPO=~/hw_sw_opt
RESULTS="$REPO/results/crypto_pyaes"
mkdir -p "$RESULTS"
cd "$REPO"

# ensure deps (quiet)
python3 -m pip install -U pyperformance pyaes pyperf psutil >/dev/null

# raw benchmark (no perf)
python3 -m pyperformance run --bench crypto_pyaes -o "$RESULTS/baseline.json"
python3 -m pyperformance show "$RESULTS/baseline.json" > "$RESULTS/baseline.txt"

# perf profile + flamegraph (assumes ~/FlameGraph exists)
rm -f perf.data perf.data.old
perf record -F 999 -g -- python3 -m pyperformance run --bench crypto_pyaes -o "$RESULTS/baseline_perfed.json"
perf report --stdio --header > "$RESULTS/perf_report_baseline.txt"
if [ -x ~/FlameGraph/stackcollapse-perf.pl ] && [ -x ~/FlameGraph/flamegraph.pl ]; then
  perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > "$RESULTS/flamegraph_baseline.svg"
fi

echo "Done. See $RESULTS"
