![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/verify/badge.svg) ![](../../workflows/site/badge.svg)

# CPU Design Mini-Project - RV32u

Design, verify and tape out a 14-instruction multi-cycle RISC-V core on Tiny Tapeout IHP.

RV32u (RV32I-Micro) is a multi-cycle core for a 14-instruction subset of RV32I: enough to run C compiled with GCC. You write the core in SystemVerilog, verify it in lockstep against a Python reference model, choose its on-chip memory (an IHP SRAM macro or flip-flops), design how the chip is loaded and observed, and harden it for a Tiny Tapeout IHP SG13CMOS5L shuttle.

**The specification and the milestones are on the project site**, published to this repo's GitHub Pages (source in [docs/](docs/)). The same site carries the **layout viewer** for the latest GDS build.

A SHaRC mini-project by James Ashie Kotey.

## Quick start

```bash
make setup        # Python environment (uv) + the IHP SRAM models (sparse submodule)
make check-env    # which tools you have, and how to install the rest
make sw lint isa  # build the test programs, lint, run the per-instruction tests
```

On the starter, `make isa` fails: the core modules are skeletons for you to fill in. Start at [Getting started](docs/guide/getting-started.md), then [M1](docs/milestones/m1-building-blocks.md).

| Target | Does |
|---|---|
| `make isa`, `make c` | the per-instruction and C-program tests, in lockstep with the reference model |
| `make test` | lint, isa, c and the Tiny Tapeout smoke test |
| `make mem-check` | do your RAM and the TT/FuseSoC files agree? (design decision D1) |
| `make design-check` | is every design decision in [DESIGN.md](DESIGN.md) filled in? |
| `make help` | everything else |

Add `SIM=icarus` to simulate with Icarus Verilog instead of Verilator (Verilator must be 5.036 or newer).

## Layout

| Path | What |
|---|---|
| `src/hw/rtl/cpu_ss/` | **your CPU**: register file, ALU, immediate generator, control FSM, datapath |
| `src/hw/rtl/io_ss/` | **your** program loader and I/O registers |
| `src/hw/rtl/mem_ss/` | the memory subsystem: the provided bus adapter, and **your** RAM |
| `src/hw/pd/` | the Tiny Tapeout top level, the macro black boxes, the PDN config, and **your** SRAM wrappers (`wrappers/`) |
| `src/hw/rtl/rv32u_soc.sv`, `src/hw/pd/tt_um_sharc_rv32u.sv` | the system and the Tiny Tapeout top level |
| `ip/` | IHP-Open-PDK (sparse submodule: the SRAM models only) |
| `src/sw/` | startup code, linker script, ISA tests, C programs, the subset legalizer |
| `src/hw/dv/` | the reference model, the lockstep harness and the tests (FuseSoC + cocotb) |
| `test/` | the Tiny Tapeout cocotb test (RTL and gate level) |
| `docs/` | the site: guide, specification, milestones; `docs/info.md` is the TT datasheet |
| `scripts/` | toolchain install, environment check, memory and design checks, diagram rendering |
| `DESIGN.md` | **your** design decisions |

## Tiny Tapeout

`info.yaml` describes the project (top module `tt_um_sharc_rv32u`, 6x2 tiles, 50 MHz). Every push runs the Tiny Tapeout [GDS](.github/workflows/gds.yaml) and [datasheet](.github/workflows/docs.yaml) actions; enable GitHub Pages (Settings, Pages, Source: GitHub Actions). A repository has one Pages site, so the layout viewer is built into the project site under `viewer/` (`site.yml`, called by `gds.yaml`) instead of replacing it. The SRAM macros use Tiny Tapeout's LibreLane power plugin (`librelane_plugin_sram_pdn.py`, `odb_stripes.py`).

## Credits

See [CREDITS.md](CREDITS.md). The site structure comes from the UofT ASIC course template by Raj Prajapati; the SRAM flow from Tiny Tapeout's IHP SRAM example.

## License

[Apache-2.0](LICENSE).
