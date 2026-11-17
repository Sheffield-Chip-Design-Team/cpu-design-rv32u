# Agent notes

Instructions for AI assistants working in this repository.

## What this is

A mini-project: students implement a 14-instruction multi-cycle RISC-V core (RV32u) in SystemVerilog and tape it out on Tiny Tapeout IHP. The site in `docs/` (Quarto) is the specification. `src/hw/rtl/cpu_ss/` and `src/hw/rtl/io_ss/` are skeletons that students fill in; everything else is provided infrastructure.

## Rules

- **Do not implement the student's core** in `src/hw/rtl/cpu_ss/` or `src/hw/rtl/io_ss/` unless the user is an instructor working on the starter. The skeletons must lint clean and fail the tests.
- `solution/` is the gitignored reference solution (`make ... SOLUTION=1 RAM=512x32|2x512x16|flops`; Tiny Tapeout configs in `solution/config/`). Never commit it, and never copy it into `src/` or `docs/`.
- Keep the RTL in the subset Verilator, Icarus Verilog 12 and Yosys all accept (spec chapter 4, R4.1-R4.5): no `import`, one package (`rv32u_pkg`), per-field struct assignment, casts on enum conditionals.
- The tests check retirement equivalence with the reference model only, not cycle counts or FSM states (spec chapter 5).
- The RAM (`src/hw/rtl/mem_ss/rv32u_ram.sv`, `src/hw/pd/wrappers/`) and its description (`RAM_WORDS`, `rv32u_wrappers.core`, `info.yaml`, `src/config.json`) are the student's D1; the starter has a stub RAM and a macro-free `config.json`. `make mem-check` checks they agree.
- Pages follow the course path: guide pages explain, spec chapters state requirements (R) and design decisions (D), milestone pages are the only ones with steps to run. Answers to questions go in `<details><summary>Answer</summary>` blocks.

## Checks

```bash
make lint model-test                        # always
make test SIM=icarus SOLUTION=1             # instructors: the reference passes
uv run --group docs scripts/render-wavedrom.py --check
quarto render docs && python3 scripts/check_site.py docs/_site
```
