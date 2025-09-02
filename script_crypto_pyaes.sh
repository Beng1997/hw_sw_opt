#!/bin/bash

# Define output filenames
PERF_DATA_PYAES="perf.pyaes.data"
PERF_DATA_FAST="perf.fast_crypto_long.data"
FLAMEGRAPH_PYAES_SVG="pyaes_flamegraph.svg"
FLAMEGRAPH_FAST_SVG="fast_crypto_long_flamegraph.svg"
RESULTS_JSON_PYAES="pyaes_results.json"
RESULTS_JSON_FAST="fast_crypto_results.json"
PERF_COMP_TXT="performance_comparison.txt"

# --- Profiling ---
# -F 999: Profiles at 999Hz, a prime number to avoid sampling alignment with periodic events.
# -g: Enables call graph (stack trace) recording.
# -o: Specifies the output file for the recorded data.
# --: Separates 'perf' arguments from the command to be profiled.
sudo perf record -F 999 -g -o "$PERF_DATA_PYAES" -- python3-dbg -m pyperformance run --bench crypto_pyaes
sudo FAST_LOOPS=600000 perf record -F 999 -g -o "$PERF_DATA_FAST" -- python3-dbg fast_crypto.py

# --- Flame Graph Creation ---
# -i: Specifies the input file for 'perf script'.
# |: Pipes the output of 'perf script' to the next command.
# >: Redirects the output to a file.
sudo perf script -i "$PERF_DATA_PYAES" | ./FlameGraph/stackcollapse-perf.pl > pyaes.folded
sudo perf script -i "$PERF_DATA_FAST" | ./FlameGraph/stackcollapse-perf.pl > fast_crypto_long.folded
./FlameGraph/flamegraph.pl pyaes.folded > "$FLAMEGRAPH_PYAES_SVG"
./FlameGraph/flamegraph.pl fast_crypto_long.folded > "$FLAMEGRAPH_FAST_SVG"

# --- Performance Comparison ---
# -o: Specifies the output file to save the benchmark results.
# --table: Displays the comparison results in a human-readable table format.
python3 -m pyperformance run --bench crypto_pyaes -o "$RESULTS_JSON_PYAES"
python3 fast_crypto.py -o "$RESULTS_JSON_FAST"
python3 -m pyperf compare --table "$RESULTS_JSON_FAST" "$RESULTS_JSON_PYAES" > "$PERF_COMP_TXT"
