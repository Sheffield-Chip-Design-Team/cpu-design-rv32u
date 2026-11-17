# Scripts

| Script | Purpose |
|--------|---------|
| `check-env.sh` | Report which tools the flow needs, which you have, and how to install the rest (`make check-env`) |
| `install-riscv-prebuilt.sh` | Install a prebuilt RISC-V GCC that targets rv32i: the distro package, or the xPack release (`--xpack`) |
| `build-verilator.sh` | Build a pinned Verilator (5.036 or newer, for cocotb 2.0) into a prefix you own |
| `init-submodules.sh` | Fetch only the IHP SRAM models from IHP-Open-PDK (sparse, partial clone) (`make setup`) |
| `select-memory.py` | Design decision D1: select the RAM option, and rewrite every file that depends on it (`make memory`) |
| `check_design.py` | Check that every field in `DESIGN.md` is filled in (`make design-check`) |
| `render-wavedrom.py` | Render the WaveDrom timing diagrams in `docs/assets/wavedrom/` to SVG (`uv run --group docs ...`) |
| `check_site.py` | Check that every local link and `#anchor` in the rendered site resolves (`.github/workflows/site.yml`) |

Run them from the repo root. Each prints its usage with `--help`.
