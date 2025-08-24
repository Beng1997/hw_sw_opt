#!/usr/bin/env bash
# ========================================================
# Script: run_crypto_pyaes_pgo.sh
# Purpose: Build an optimized CPython (PGO+LTO) and run the
#          crypto_pyaes benchmark from pyperformance.
#
# Outputs in results/crypto_pyaes/:
#   - before.json  : baseline (system Python)
#   - after.json   : optimized CPython run
#   - compare.txt  : before vs after comparison
# ========================================================

set -euo pipefail   # safer bash: exit on errors, unset vars, and pipe fails

# ------------------------------
# Paths and version numbers
# ------------------------------
REPO=~/hw_sw_opt
PYVER=3.10.12
BUILD=/tmp/Python-$PYVER
RESULTS=$REPO/results/crypto_pyaes

mkdir -p "$RESULTS"

# ------------------------------
# Step 0. Update system & fix packages
# ------------------------------
echo ">>> Updating system and fixing broken packages..."
sudo apt update
sudo apt full-upgrade -y || true
sudo apt --fix-broken install -y || true
sudo apt autoremove -y
sudo apt clean

# ------------------------------
# Step 1. Install build dependencies
# ------------------------------
echo ">>> Installing build dependencies..."
sudo apt install -y build-essential \
    libssl-dev zlib1g-dev libffi-dev \
    libncurses5-dev libsqlite3-dev libreadline-dev \
    libbz2-dev liblzma-dev uuid-dev wget

# ------------------------------
# Step 2. Run baseline if missing
# ------------------------------
if [ ! -f "$RESULTS/before.json" ]; then
    echo ">>> Running baseline with system Python..."
    python3 -m pip install --user -q --upgrade pyperformance pyaes pyperf psutil
    python3 -m pyperformance run --bench crypto_pyaes \
        -o $RESULTS/before.json
    python3 -m pyperformance compare \
        $RESULTS/before.json $RESULTS/before.json \
        > $RESULTS/before.txt
    echo ">>> Baseline saved to $RESULTS/before.json"
else
    echo ">>> Baseline already exists at $RESULTS/before.json"
fi

# ------------------------------
# Step 3. Download CPython source
# ------------------------------
echo ">>> Fetching CPython $PYVER sources..."
cd /tmp
if [ ! -d "$BUILD" ]; then
    wget -nc https://www.python.org/ftp/python/$PYVER/Python-$PYVER.tgz
    tar xf Python-$PYVER.tgz
fi

# ------------------------------
# Step 4. Build optimized CPython
# ------------------------------
echo ">>> Building optimized CPython..."
cd "$BUILD"
./configure --enable-optimizations --with-lto
make -j"$(nproc)"

NEWPY=$BUILD/python   # path to the new optimized interpreter

# ------------------------------
# Step 5. Install pyperformance and deps into optimized CPython
# ------------------------------
echo ">>> Installing pyperformance and dependencies..."
$NEWPY -m pip install --upgrade pip
$NEWPY -m pip install pyperformance pyaes pyperf psutil

# ------------------------------
# Step 6. Run the benchmark with optimized CPython
# ------------------------------
echo ">>> Running crypto_pyaes benchmark with optimized CPython..."
$NEWPY -m pyperformance run --bench crypto_pyaes \
    -o $RESULTS/after.json

# ------------------------------
# Step 7. Compare baseline vs optimized
# ------------------------------
echo ">>> Comparing baseline (before.json) with optimized (after.json)..."
$NEWPY -m pyperformance compare \
    $RESULTS/before.json \
    $RESULTS/after.json \
    | tee $RESULTS/compare.txt

# ------------------------------
# Done
# ------------------------------
echo ">>> Done."
echo "Results available in: $RESULTS"
ls -lh $RESULTS/before.json $RESULTS/after.json $RESULTS/compare.txt

