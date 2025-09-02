# Hardware and Software Optimization

## Repository Structure

- **Scripts/**: Contains Python files and shell scripts for benchmarking
  - `fast_crypto.py`: AES encryption implementation with C extensions
  - `script_crypto_pyaes.sh`: Benchmark script for AES encryption
  - `json_benchmarks/`: Subfolder containing JSON serialization benchmarks
    - `fast_json.py`: JSON serialization using Rust-based libraries
    - `script_json.sh`: Benchmark script for JSON serialization
  - `utils/`: Helper functions for benchmarking and data processing
    - `common.py`: Common utilities shared across benchmarks
    - `profiling.py`: Profiling utilities for performance analysis

- **reports/**: Performance benchmark results
  - `crypto/`: AES encryption benchmark results
  - `json/`: JSON serialization benchmark results
  - `charts/`: Generated performance comparison charts

- **extensions/**: C and Rust extension code
  - `c_modules/`: C extension modules
    - `aes_module/`: C implementation of AES encryption
  - `rust_modules/`: Rust extension modules
    - `json_module/`: Rust implementation of JSON serialization

- **venv/**: Python virtual environment (created during setup)

## Dependencies

All required dependencies are listed in the `requirements.txt` file, including:
- `pyperf`: For reliable Python benchmarking
- `cryptography`: For cryptographic operations
- `matplotlib`: For generating performance charts
- `numpy`: For numerical operations
- `orjson`: Rust-based JSON library

The C and Rust extensions require:
- A C compiler (gcc/clang) for C extensions
- Rust compiler (cargo) for Rust extensions

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Beng1997/hw_sw_opt.git
   cd hw_sw_opt
   ```

2. Set up virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Build extensions (if needed):
   ```bash
   cd extensions/c_modules/aes_module
   python setup.py install
   cd ../../rust_modules/json_module
   cargo build --release
   ```

## Running Scripts

Run the AES encryption benchmark:
```bash
cd Scripts
./script_crypto_pyaes.sh
```

Run the JSON serialization benchmark:
```bash
cd Scripts/json_benchmarks
./script_json.sh
```

Results will be stored in the corresponding subfolders of the `reports/` directory.