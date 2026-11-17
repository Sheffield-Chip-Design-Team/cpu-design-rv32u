# Tiny Tapeout test

`make` runs a smoke test of the Tiny Tapeout top level, `tt_um_sharc_rv32u`, on Icarus:
reset, run, and check every output pin is driven. `make GATES=yes` runs the same test on
the gate-level netlist; the GDS action does this for you (`gl_test`).

The core is verified by the FuseSoC flow at the repo root instead: `make test` (see
`docs/spec/09-verification.md`). Extend `test.py` to drive your loader (decision D2)
and read your I/O (D3-D5) through the pins, so the gate-level run checks them too.

Requirements: `pip install -r requirements.txt` (cocotb, pytest) and Icarus Verilog 12.
The RTL run takes the SRAM models from `../ip/IHP-Open-PDK`
(`scripts/init-submodules.sh`).
