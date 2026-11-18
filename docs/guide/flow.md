# The flow

This page maps the repository: which files you edit, what each `make` target runs, and how the pieces connect, from C source to a Tiny Tapeout GDS.

## The repository

| Path | What | Yours? |
|---|---|---|
| `src/hw/rtl/cpu_ss/` | the CPU: `rv32u_cpu_ss` (fixed ports) and the modules you split it into (D7), optional shared types in `rv32u_ctrl.svh` | **yes** |
| `src/hw/rtl/io_ss/` | the program loader and the I/O registers (D2-D5) | **yes** |
| `src/hw/rtl/rv32u_pkg.sv` | encodings, selectors, the memory map | no |
| `src/hw/rtl/mem_ss/` | the memory subsystem: the bus adapter (provided), your RAM `rv32u_ram.sv` and its size, the `RAM_WORDS` parameter (D1) | the RAM |
| `src/hw/pd/wrappers/` | your IHP SRAM macro wrappers, if your RAM uses macros (D1) | **yes** |
| `src/hw/rtl/rv32u_soc.sv`, `src/hw/pd/tt_um_sharc_rv32u.sv` | the system and the Tiny Tapeout top level | the pin mapping (D5) |
| `src/config.json`, `src/hw/pd/pdn_cfg.tcl`, `src/hw/pd/sram_bb.sv` | LibreLane hardening configuration, the macros' black boxes | `config.json`'s SRAM entries (D1) |
| `info.yaml` | the Tiny Tapeout project description: top module, sources, tiles, pinout | the pinout (D5) |
| `ip/` | the IHP SRAM models (a sparse submodule) and their FuseSoC core | no |
| `src/sw/` | `crt0.S`, the linker script, the ISA tests (`isa/*.S`), the C programs (`c/*.c`), the legalizer | add your programs |
| `src/hw/dv/` | the reference model, the lockstep harness, the ISA and C tests | add your unit tests |
| `test/` | the Tiny Tapeout cocotb test (RTL and gate level) | extend it (M4) |
| `DESIGN.md` | your design decisions | **yes** |
| `docs/` | this site | no |

## From C to a passing test

```
src/sw/c/fib.c --gcc -S--> fib.s --legalize.py--> fib.legal.s --gcc + crt0.S, link.ld--> fib.elf
    --check_subset.py (only the 14 instructions?)--> --objcopy, bin2hex--> src/sw/build/c/fib.hex
```

1. `make -C src/sw` compiles each program with `-march=rv32i -mabi=ilp32 -O0 -nostdlib`. `legalize.py` rewrites the few RV32I instructions that GCC emits outside the subset (such as `bne` and `slli`) into ones inside it. `check_subset.py` then fails the build if any other instruction remains ([chapter 8](../spec/08-software-flow.md)).
2. The test (`src/hw/dv/test_isa.py` or `src/hw/dv/test_c.py`) loads the `.hex` into the RAM through the simulator, releases reset, and runs your core and the reference model (`src/hw/dv/model/rv32u_iss.py`) in lockstep. Every retired instruction must match ([chapter 9](../spec/09-verification.md)).
3. At the halt, the `expect:` results in the program's header are checked.

## The `make` targets

| Target | Runs |
|---|---|
| `make setup` | `uv sync`, and the sparse SRAM-model checkout |
| `make check-env` | `scripts/check-env.sh` |
| `make sw` | `make -C src/sw`: every ISA test and C program |
| `make lint` | FuseSoC target `lint` of `sharc:rv32u:soc`: Verilator `-Wall` |
| `make isa`, `make c` | FuseSoC targets `isa`/`c` (or `isa_icarus`/`c_icarus`) of `sharc:rv32u:tb` |
| `make tt-test` | `make -C test`: the Tiny Tapeout smoke test |
| `make test` | lint, isa, c and tt-test |
| `make model-test` | pytest on the reference model |
| `make design-check` | `scripts/check_design.py`: is every `DESIGN.md` field filled in? |
| `make mem-check` | `scripts/check_memory.py`: do your RAM, its size, the cores, `info.yaml` and `config.json` agree? (D1) |
| `make site` | `quarto render docs` |

Options: `SIM=icarus` simulates with Icarus Verilog; `WAVES=1` dumps a waveform (Icarus); `COCOTB_TEST_FILTER=<name>` runs one test.

## FuseSoC

[FuseSoC](https://fusesoc.readthedocs.io) describes each part of the design as a *core* (a `.core` file) with its files and its build targets. `make` calls it with explicit core roots:

```bash
uv run fusesoc --cores-root src/hw --cores-root ip \
    run --no-export --target=isa sharc:rv32u:tb
```

| Core | File | Contains |
|---|---|---|
| `sharc:rv32u:pkg` | `src/hw/rtl/rv32u_pkg.core` | the package (and your `rv32u_ctrl.svh`) |
| `sharc:rv32u:cpu_ss` | `src/hw/rtl/cpu_ss/rv32u_cpu_ss.core` | your CPU |
| `sharc:rv32u:mem_ss` | `src/hw/rtl/mem_ss/rv32u_mem_ss.core` | the bus adapter (and the `RAM_WORDS` parameter) |
| `sharc:rv32u:ram` | `src/hw/rtl/mem_ss/rv32u_ram.core` | your RAM |
| `sharc:rv32u:wrappers` | `src/hw/pd/wrappers/rv32u_wrappers.core` | your macro wrappers (empty for flip-flops) |
| `sharc:rv32u:io_ss` | `src/hw/rtl/io_ss/rv32u_io_ss.core` | your loader and I/O |
| `sharc:rv32u:soc` | `src/hw/rv32u.core` | the system, the Tiny Tapeout top, the macro black boxes, the `lint` target |
| `sharc:ip:ihp_sram` | `ip/ihp_sram.core` | the SRAM behavioural models |
| `sharc:rv32u:tb` | `src/hw/dv/rv32u_tb.core` | the cocotb targets: `isa`, `c`, and your `unit_*` targets |

Builds go to `build/sharc_rv32u_tb_0.1.0/<target>/`, with the simulator's log, `results.xml` and any waveform.

## Tiny Tapeout

The Tiny Tapeout flow runs in GitHub Actions on every push ([chapter 10](../spec/10-tiny-tapeout.md)):

| Workflow | Jobs |
|---|---|
| `.github/workflows/gds.yaml` | `gds` (LibreLane hardening with the SRAM power plugin), `precheck`, `gl_test` (the `test/` cocotb test on the netlist), `viewer` (rebuilds the site with the new layout) |
| `.github/workflows/docs.yaml` | the Tiny Tapeout datasheet from `docs/info.md` |
| `.github/workflows/site.yml` | this site, published to the repo's GitHub Pages, with the latest layout under `viewer/` |
| `.github/workflows/verify.yaml` | lint, the ISA and C tests, and the `DESIGN.md` check |

`info.yaml`, `src/config.json` and the FuseSoC cores must describe the RAM you built; you edit them by hand ([chapter 7](../spec/07-memory-subsystem.md#applying-your-choice)), and `make mem-check` checks them.
