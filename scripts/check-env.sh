#!/usr/bin/env bash
# Report which tools the RV32u flow needs, which you have, and how to get the rest.
#   scripts/check-env.sh        (or: make check-env)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ok=0; missing=0
green() { printf '  \033[32mok\033[0m       %-22s %s\n' "$1" "$2"; ok=$((ok + 1)); }
red()   { printf '  \033[31mmissing\033[0m  %-22s %s\n' "$1" "$2"; missing=$((missing + 1)); }
warn()  { printf '  \033[33mwarn\033[0m     %-22s %s\n' "$1" "$2"; }
have()  { command -v "$1" >/dev/null 2>&1; }
ver_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

echo "Required"

if have uv; then green uv "$(uv --version)"; else red uv "https://docs.astral.sh/uv/getting-started/installation/"; fi

CROSS=""
for p in riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf-; do
  if have "${p}gcc"; then CROSS="$p"; break; fi
done
if [[ -n "$CROSS" ]]; then
  if echo 'int main(void){return 0;}' | "${CROSS}gcc" -march=rv32i -mabi=ilp32 -nostdlib \
       -ffreestanding -x c -c -o /dev/null - 2>/dev/null; then
    green "${CROSS}gcc" "$("${CROSS}gcc" --version | head -1) (rv32i ok)"
  else
    red "${CROSS}gcc" "cannot build -march=rv32i -mabi=ilp32: scripts/install-riscv-prebuilt.sh --xpack"
  fi
else
  red "RISC-V GCC" "scripts/install-riscv-prebuilt.sh"
fi

if have verilator; then
  V="$(verilator --version | awk '{print $2}')"
  if ver_ge "$V" 5.036; then green verilator "$V"; else
    red verilator "$V is older than 5.036 (cocotb 2.0 needs it): scripts/build-verilator.sh, or use SIM=icarus"
  fi
else
  red verilator "scripts/build-verilator.sh (or use SIM=icarus)"
fi

if have iverilog; then
  I="$(iverilog -V 2>&1 | head -1 | awk '{print $4}')"
  if ver_ge "$I" 12.0; then green iverilog "$I"; else red iverilog "$I: Icarus 12 or newer is needed (-g2012)"; fi
else
  red iverilog "sudo apt-get install iverilog (used by the Tiny Tapeout test, and SIM=icarus)"
fi

if [[ -d "$ROOT/.venv" ]] && "$ROOT/.venv/bin/python" -c "import cocotb, fusesoc" 2>/dev/null; then
  green "python env" "$("$ROOT/.venv/bin/python" -c 'import cocotb; print("cocotb", cocotb.__version__)'), fusesoc"
else
  red "python env" "uv sync (or: make setup)"
fi

if [[ -f "$ROOT/ip/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/verilog/RM_IHPSG13_1P_512x32_c2_bm_bist.v" ]]; then
  green "IHP SRAM models" "ip/IHP-Open-PDK"
else
  red "IHP SRAM models" "scripts/init-submodules.sh (or: make setup)"
fi

echo "Optional"
if have quarto; then green quarto "$(quarto --version) (make site)"; else warn quarto "https://quarto.org/docs/get-started/ (to render the web page)"; fi
if have yosys; then green yosys "$(yosys -V | awk '{print $2}') (quick synthesis checks)"; else warn yosys "part of OSS CAD Suite"; fi
if have docker; then green docker "$(docker --version | cut -d, -f1) (local hardening via .devcontainer)"; else warn docker "only for hardening locally; the GDS action hardens in CI"; fi
if have gtkwave || have surfer; then green "waveform viewer" "$(have surfer && echo surfer || echo gtkwave)"; else warn "waveform viewer" "gtkwave or surfer, to view .fst traces"; fi

echo
if [[ $missing -eq 0 ]]; then echo "all required tools present"; else echo "$missing required tool(s) missing"; exit 1; fi
