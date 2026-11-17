# 11. Deliverables and acceptance

## Deliverables

1. **The core:** your `src/hw/rtl/cpu_ss/` (register file, ALU, immediate generator, control unit, datapath and `rv32u_ctrl.svh`).
2. **The chip:** your loader and I/O (`src/hw/rtl/io_ss/`), the pin mapping in `src/hw/rtl/rv32u_soc.sv`, `info.yaml` (pinout) and `docs/info.md` (how it works, how to test it).
3. **Unit tests:** for at least the register file, the ALU and the immediate generator ([chapter 9](09-verification.md)), with FuseSoC targets.
4. **At least one C program of your own** in `src/sw/c/`, with an `expect:` line, that the C tests run.
5. **`DESIGN.md`:** every design decision, D1 to D8, answered.

## Acceptance

| | Criterion | How it is checked |
|---|---|---|
| A1 | Lint clean | `make lint` |
| A2 | Every per-instruction test passes (retirement equivalent to the reference model) | `make isa` |
| A3 | Every C program passes, including yours | `make c` |
| A4 | Your unit tests pass and cover R9.1 | your FuseSoC targets; review |
| A5 | The Tiny Tapeout smoke test passes, RTL and gate level | `make tt-test`; the `gl_test` action |
| A6 | The chip hardens: GDS and precheck green, timing met at 50 MHz | the `gds` and `precheck` actions |
| A7 | `DESIGN.md` is complete | `make design-check`; review |
| A8 | The core is observable on the pins: a loaded program's result can be seen | review of D2-D5 and `test/test.py` |

## Going further (optional)

- Measure CPI on the chip with a cycle counter (D3), and compare it with the simulation's.
- Cut the CPI: merge states, or overlap the next fetch with the current instruction's last step, and compare the cycles in `make c` before and after.
- Add `BNE` and `BGE` (they cost almost nothing) and drop the legalizer's branch rewrites: change the spec, the model and the tests together.
- Hold the register file in latches or an IHP two-port SRAM to cut its area, and see whether the chip then fits 4x2 tiles.
