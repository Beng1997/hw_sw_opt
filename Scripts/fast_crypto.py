# filename: fast_crypto.py
"""
Optimized version of the 'crypto_pyaes' benchmark using OpenSSL (via cryptography).
"""

import os
import time
import pyperf
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

# --- Workload parameters matched to original pyaes benchmark ---
CLEARTEXT = b"This is a test. What could possibly go wrong? " * 500  # ~23 KB
KEY = b'\xa1\xf6%\x8c\x87}_\xcd\x89dHE8\xbf\xc9,'  # 16 bytes (128-bit)
NONCE = b"\x00" * 16  # fixed CTR nonce like pyaes default
BLOCKS = 1000         # multiplier for pyperf inner loop


def _one_iteration():
    """Encrypt+decrypt one 23KB buffer with AES-CTR; return True if valid."""
    cipher = Cipher(algorithms.AES(KEY), modes.CTR(NONCE))
    enc = cipher.encryptor()
    ct = enc.update(CLEARTEXT) + enc.finalize()

    cipher2 = Cipher(algorithms.AES(KEY), modes.CTR(NONCE))
    dec = cipher2.decryptor()
    pt = dec.update(ct) + dec.finalize()

    return pt == CLEARTEXT


def bench_fast_crypto(loops: int) -> float:
    """pyperf-compatible: do (loops * BLOCKS) iterations and return total time."""
    iters = loops * BLOCKS
    t0 = pyperf.perf_counter()
    for _ in range(iters):
        if not _one_iteration():
            raise RuntimeError("decrypt mismatch")
    t1 = pyperf.perf_counter()
    return t1 - t0


def _perf_driver():
    """Driver for perf record. Control runtime with FAST_LOOPS env var (default=5000)."""
    loops = int(os.environ.get("FAST_LOOPS", "5000"))
    ok = True
    t0 = time.perf_counter()
    for _ in range(loops):
        ok &= _one_iteration()
    dt = time.perf_counter() - t0
    mb = (len(CLEARTEXT) * loops) / (1024 * 1024)
    print(f"Ran {loops} iterations (~{mb:.1f} MiB) in {dt:.2f}s -> {mb/dt:.1f} MiB/s")
    if not ok:
        raise RuntimeError("Validation failed")


if __name__ == "__main__":
    import sys
    if any(arg.startswith("-") for arg in sys.argv[1:]):  # pyperf mode
        runner = pyperf.Runner()
        runner.metadata['description'] = "AES-CTR (~23KB) encrypt+decrypt with cryptography/OpenSSL"
        runner.bench_time_func('fast_crypto', bench_fast_crypto)
    else:  # plain run for perf record
        _perf_driver()
