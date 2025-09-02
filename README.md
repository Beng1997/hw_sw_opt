# Hardware and Software Optimization

## Repository Structure

- **Scripts/**: Contains Python files and shell scripts for benchmarking
  - `fast_crypto.py`: AES encryption implementation
  - `script_crypto_pyaes.sh`: Benchmark script
- **reports/**: Performance benchmark results
- **venv/**: Python virtual environment

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

## Running Scripts

Run the benchmark script:
```bash
cd Scripts
./script_crypto_pyaes.sh
```

Results will be stored in the `reports/` directory.