#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/hw_sw_opt}"
RESULTS="$REPO/results/crypto_pyaes"
mkdir -p "$RESULTS"
cd "$REPO"

# timestamped names
TS=$(date +%Y%m%d-%H%M%S)
BASE="baseline_${TS}"
OUT_JSON="$RESULTS/${BASE}.json"
OUT_TXT="$RESULTS/${BASE}.txt"
PERF="$RESULTS/perf.${BASE}.data"
OUT_JSON_PERF="$RESULTS/${BASE}_perfed.json"
SVG="$RESULTS/flamegraph_${BASE}.svg"

# pick an interpreter: prefer python3-dbg if present
if command -v python3-dbg >/dev/null 2>&1; then PY=python3-dbg; else PY=python3; fi

# deps (quiet)
$PY -m pip -q install --user -U pyperformance pyaes pyperf psutil >/dev/null 2>&1 || true

# optional: reduce perf warnings
if [ "$(id -u)" = "0" ]; then
  sysctl -q kernel.perf_event_paranoid=1 || true
  sysctl -q kernel.kptr_restrict=0 || true
fi

echo ">>> Running plain benchmark..."
$PY -m pyperformance run --bench crypto_pyaes -o "$OUT_JSON"
$PY -m pyperformance show "$OUT_JSON" > "$OUT_TXT"

echo ">>> Recording perf profile..."
rm -f "$PERF"
perf record -o "$PERF" -F 999 -g -- \
  $PY -m pyperformance run --bench crypto_pyaes -o "$OUT_JSON_PERF"

echo ">>> Writing textual perf report..."
perf report -i "$PERF" --stdio --header > "$RESULTS/perf_report_${BASE}.txt" || true

echo ">>> Building flamegraph..."
if [ ! -x "$HOME/FlameGraph/stackcollapse-perf.pl" ]; then
  git clone https://github.com/brendangregg/FlameGraph.git "$HOME/FlameGraph" >/dev/null 2>&1 || true
fi
if [ -x "$HOME/FlameGraph/stackcollapse-perf.pl" ] && [ -x "$HOME/FlameGraph/flamegraph.pl" ]; then
  perf script -i "$PERF" \
    | "$HOME/FlameGraph/stackcollapse-perf.pl" \
    | "$HOME/FlameGraph/flamegraph.pl" > "$SVG"
else
  echo "FlameGraph tools not found; skipped SVG."
fi

echo ">>> Artifacts:"
ls -lh "$OUT_JSON" "$OUT_TXT" "$OUT_JSON_PERF" || true
ls -lh "$RESULTS/perf_report_${BASE}.txt" || true
test -f "$SVG" && echo "FlameGraph: $SVG"
echo "Done."
