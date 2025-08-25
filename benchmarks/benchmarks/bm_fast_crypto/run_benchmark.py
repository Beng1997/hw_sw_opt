import os
import pyperf
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

# Match the original crypto_pyaes workload shape:
# - AES-CTR
# - 128-bit key
# - ~23 KB message per inner iteration
CLEARTEXT = b"This is a test. What could possibly go wrong? " * 500   # ~23 KB
KEY = b'\xa1\xf6%\x8c\x87}_\xcd\x89dHE8\xbf\xc9,'  # 16 bytes (128-bit)
NONCE = b"\x00" * 16  # fixed CTR nonce/counter per iteration (like pyaes default)
BLOCKS = 1000         # extra inner work per "loop" unit (pyperf multiplies loops)

def _one_iter() -> bool:
    # Encrypt
    cipher = Cipher(algorithms.AES(KEY), modes.CTR(NONCE))
    enc = cipher.encryptor()
    ct = enc.update(CLEARTEXT) + enc.finalize()
    # Decrypt (new cipher, same NONCE)
    cipher2 = Cipher(algorithms.AES(KEY), modes.CTR(NONCE))
    dec = cipher2.decryptor()
    pt = dec.update(ct) + dec.finalize()
    return pt == CLEARTEXT

def bench_fast_crypto(loops: int) -> float:
    iters = loops * BLOCKS
    t0 = pyperf.perf_counter()
    for _ in range(iters):
        if not _one_iter():
            raise RuntimeError("Decrypted plaintext mismatch")
    t1 = pyperf.perf_counter()
    return t1 - t0

if __name__ == "__main__":
    r = pyperf.Runner()
    r.metadata['description'] = "AES-CTR (~23 KB/op) using cryptography/OpenSSL"
    r.bench_time_func("fast_crypto", bench_fast_crypto)
