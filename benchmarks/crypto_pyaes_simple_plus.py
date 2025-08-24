#!/usr/bin/env python3
"""
crypto_pyaes_simple_plus.py — Same logic as the pyperformance crypto_pyaes:
  per loop:
    - AES-CTR encrypt 23 kB with a fixed 128-bit key
    - reinit AES-CTR, decrypt back
    - verify equality

Improvements (without changing the algorithm/work):
  • Fewer attribute lookups inside the loop (cache to locals)
  • Optional CPU affinity & niceness to reduce run-to-run noise
  • Richer metadata (payload size, affinity, nice, versions) in the result
"""

import argparse
import os
import platform
import sys

import pyperf
import pyaes

# Same payload/key as the upstream benchmark (23,000 bytes)
BASE_CHUNK = b"This is a test. What could possibly go wrong? "
DEFAULT_MULT = 500  # 46 bytes * 500 ~= 23 KB
KEY = b"\xa1\xf6%\x8c\x87}_\xcd\x89dHE8\xbf\xc9,"

def make_message(mult: int = DEFAULT_MULT) -> bytes:
    return BASE_CHUNK * mult

def bench_factory(msg: bytes):
    AESCTR = pyaes.AESModeOfOperationCTR  # cache to local
    perf_counter = pyperf.perf_counter
    key = KEY

    def bench(loops: int) -> float:
        t0 = perf_counter()
        for _ in range(loops):
            ct = AESCTR(key).encrypt(msg)
            pt = AESCTR(key).decrypt(ct)
        dt = perf_counter() - t0
        if pt != msg:
            raise RuntimeError("decrypt error")
        return dt
    return bench

def maybe_tune_process(affinity: int | None, nice: int | None) -> None:
    # Best-effort: pin to a CPU and/or adjust niceness if requested.
    try:
        if affinity is not None:
            try:
                import psutil
                psutil.Process().cpu_affinity([affinity])
            except Exception:
                pass
        if nice is not None:
            try:
                import psutil
                psutil.Process().nice(nice)
            except Exception:
                try:
                    os.nice(nice)
                except Exception:
                    pass
    except Exception:
        pass

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--payload-mult", type=int, default=DEFAULT_MULT,
                    help="Repeat count of the 46-byte chunk (default: 500 ≈ 23 kB)")
    ap.add_argument("--affinity", type=int, default=None,
                    help="Pin process to a single CPU (e.g., 0). Optional.")
    ap.add_argument("--nice", type=int, default=None,
                    help="Set process niceness (e.g., -10..19). Optional.")
    # Parse *our* args but leave pyperf’s (e.g. -o, --rigorous) alone:
    args, rest = ap.parse_known_args()
    sys.argv = [sys.argv[0]] + rest  # keep pyperf CLI working

    maybe_tune_process(args.affinity, args.nice)

    msg = make_message(args.payload_mult)
    bench = bench_factory(msg)

    runner = pyperf.Runner()
    m = runner.metadata
    m["description"] = "Pure-Python AES-CTR (pyaes) — improved harness, same logic"
    m["payload_bytes"] = len(msg)
    m["payload_mult"] = args.payload_mult
    # Only include optional fields if provided (pyperf dislikes None)
    if args.affinity is not None:
        m["affinity"] = int(args.affinity)
    if args.nice is not None:
        m["nice"] = int(args.nice)
    m["pyaes_version"] = getattr(pyaes, "__version__", "unknown")
    m["python"] = sys.version
    m["platform"] = platform.platform()

    runner.bench_time_func("crypto_pyaes_simple_plus", bench)

if __name__ == "__main__":
    main()
