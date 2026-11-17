# Getting started

This page explains how the mini-project is laid out, and gets the tools working on your machine. By the end, `make isa` runs and fails, because the core is still yours to write.

## How the pages are organised

The [course path](../index.md#course-path) on the home page lists every page in the order to work through them. There are three kinds:

- **Guide** pages (like this one) explain the setup, the flow and where to learn more.
- **Specification** chapters say exactly what your core must do. Requirements are numbered (R5.1 and so on) and use "must"; the provided tests check them. **Design decisions** (D1-D8) are the parts that are yours. Each is in a box that gives its constraints, the options and what to record in `DESIGN.md`.
- **Milestone** pages are what you do. Each is split into numbered parts with a "You should see" check, and ends with a Finishing section that says when you are done.

When a step asks a question, its answer is in a collapsed block under it. Try it yourself first, then open "Answer".

## Tools

| Tool | For | Version |
|---|---|---|
| [uv](https://docs.astral.sh/uv/) | the Python environment: FuseSoC, cocotb, the reference model | any recent |
| RISC-V GCC | compiling the test programs: `riscv32-unknown-elf-`, `riscv64-unknown-elf-` or `riscv-none-elf-` | any that builds `-march=rv32i` |
| [Verilator](https://verilator.org) | simulation and lint | **5.036 or newer** (cocotb 2.0 needs it) |
| [Icarus Verilog](https://steveicarus.github.io/iverilog/) | the Tiny Tapeout tests and an alternative simulator (`SIM=icarus`) | 12 |
| git | the repo and the IHP SRAM submodule | 2.27 or newer (sparse checkout) |
| GTKWave or Surfer | viewing waveforms | any |
| [Quarto](https://quarto.org) | rendering this site locally (optional) | 1.5 or newer |

The hardening tools (LibreLane, the IHP PDK) run in GitHub Actions, so you do not install them.

Linux, macOS and Windows with WSL2 work. The repo's `.devcontainer/` gives a ready-made container for VS Code or GitHub Codespaces.

## Setup

1. Clone the repo, then set up the Python environment and fetch the SRAM models:

   ```bash
   git clone <your repo URL> rv32i-micro && cd rv32i-micro
   make setup
   ```

   `make setup` runs `uv sync` and `scripts/init-submodules.sh`. The script fetches only the SRAM models from IHP-Open-PDK (a few MB), not the whole PDK (several GB).

2. See what is missing:

   ```bash
   make check-env
   ```

   Each tool shows `ok` or `missing`, and a missing one comes with the command that fixes it.

3. Install what is missing:
   - RISC-V GCC: `scripts/install-riscv-prebuilt.sh` uses your distribution's package if it has one (`gcc-riscv64-unknown-elf` on Debian/Ubuntu, `riscv-gnu-toolchain` through Homebrew), otherwise it downloads the xPack release into `~/opt`. Add the `PATH` line it prints to your shell profile.
   - Verilator: if your package manager's is older than 5.036, `scripts/build-verilator.sh` builds v5.040 from source into `~/opt` (it lists the build dependencies at the top). It takes about 10 minutes.
   - Icarus Verilog: `sudo apt install iverilog` or `brew install icarus-verilog`.

You should see `make check-env` report every required tool as `ok`.

## First run

```bash
make sw       # build the test programs into sw/build/
make lint     # Verilator lint of the starter design
make isa      # the per-instruction tests
```

You should see the lint pass, and every ISA test fail with the same message:

```
add: 200 cycles without a retired instruction after 0 retired. no instruction has ever
retired: does your core fetch from address 0 after reset, and is rvfi_valid driven? (spec 05, 06)
...
** TESTS=19 PASS=0 FAIL=19 SKIP=0 **
```

That is correct: the core modules are skeletons. In [M1](../milestones/m1-building-blocks.md) you start filling them in.

If Verilator is too old for now, add `SIM=icarus` to any `make` command. The tests are the same.

## What to read next

- [The flow](flow.md): what each file and `make` target does.
- [Resources](resources.md): RISC-V, CPU design and SystemVerilog references.
- [Specification, chapter 1](../spec/01-overview.md): the overview of what you are building.
