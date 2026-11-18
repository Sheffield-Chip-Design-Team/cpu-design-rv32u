# 9. Verification

## The provided tests

Every provided test runs a program on your RTL and on a **reference model** at the same time (lockstep). The reference model is `src/hw/dv/model/rv32u_iss.py`, an instruction-set simulator of exactly this specification. Each time your core's retire port reports an instruction ([chapter 6](06-retire-and-trap.md)), the model executes one too, and every field must match. The first difference fails the test.

| Test | Programs | Checks | Run |
|---|---|---|---|
| per-instruction | `src/sw/isa/*.S`: one per instruction, plus `x0` and four traps | lockstep; the `expect:` results; cycles reported, not checked | `make isa` |
| C programs | `src/sw/c/*.c`: recursion, arrays, nested calls with function pointers, sorting, `while (a != b)` | lockstep to the final halt; the `expect:` results in RAM; CPI reported | `make c` |
| Tiny Tapeout smoke test | `test/test.py` | the chip's top level resets and drives every pin (RTL and gate level) | `make tt-test` |
| lint | the whole design as Tiny Tapeout builds it | Verilator `-Wall` | `make lint` |

`make test` runs all four. Add `SIM=icarus` to simulate with Icarus Verilog instead of Verilator.

The tests check **retirement equivalence** only: the same instructions, retired in the same order, with the same values on the retire port. They do not check how many cycles an instruction takes, or which states your FSM passes through ([chapter 5](05-control-fsm.md)). The one timing limit is R5.4: more than 200 cycles without a retired instruction counts as a hang.

The tests run through FuseSoC (`src/hw/dv/rv32u_tb.core`) and cocotb, with `rv32u_soc` as the top level. Before each test, they load the program through the memory subsystem's loader port, using a simulation-only port in `rv32u_soc` that holds the CPU in reset. So they work before you design a loader (D2), and whatever RAM you build (D1).

## Reading a failure

A lockstep failure names the instruction, the field that differs, and what came before it. For example, from an ALU that compares unsigned where `SLT` is signed:

```
dv.harness.LockstepError: slt: retired instruction #3 differs from the reference model in rd_wdata (cycle 14)
  RTL:   pc=0x00000008  slt t2, t0, t1                    x7=0x00000000  next=0x0000000c
  model: pc=0x00000008  slt t2, t0, t1                    x7=0x00000001  next=0x0000000c
  previous instructions:
    pc=0x00000000  addi t0, zero, -1                 x5=0xffffffff  next=0x00000004
    pc=0x00000004  addi t1, zero, 1                  x6=0x00000001  next=0x00000008
```

`-1 < 1` is true for a signed compare, so `x7` should be 1. Other messages tell you that no instruction has retired yet (does the core fetch from address 0 after reset, and is `rvfi_valid` driven?), that it stopped retiring (a state that never exits, or a missed `mem_ready`), or that a retire-port signal is X.

## Waveforms

- Icarus: `make isa SIM=icarus WAVES=1` writes `build/sharc_rv32u_tb_0.1.0/isa_icarus/rv32u.fst` (`c_icarus` for `make c`). Open it with `gtkwave` or `surfer`.
- Verilator: add `--trace-fst` to the `verilator_options` of the target in `src/hw/dv/rv32u_tb.core`, and dump from your own testbench code.
- To run one test only: `COCOTB_TEST_FILTER=slt make isa`.

## Your unit tests

The provided tests check the whole CPU. They will not tell you which part of it is wrong, so you must test your modules on their own as well.

- R9.1: write cocotb unit tests for the modules inside your `rv32u_cpu_ss` (D7). Whatever your split, they must cover the register file behaviour (including `x0`), every ALU operation and comparison (overflow, signed extremes), and every immediate format with both signs. If those live in one module, test that module; if you have no sub-modules at all, explain in `DESIGN.md` how you tested these instead.
- R9.2: add a FuseSoC target for each tested module, so `fusesoc ... run --target=<name> sharc:rv32u:tb` runs it. For example, in `src/hw/dv/rv32u_tb.core`:

  ```yaml
    unit_alu:
      description: ALU unit tests
      filesets: [rtl]
      toplevel: rv32u_alu        # your module's name
      flow: sim
      flow_options:
        tool: verilator
        cocotb_module: dv.unit.test_alu
  ```

  with your test in `src/hw/dv/unit/test_alu.py` (and an empty `src/hw/dv/unit/__init__.py`).
- R9.3: list your unit tests and what they cover in `DESIGN.md` or a `src/hw/dv/unit/README.md`.

The reference model's own self-tests (`make model-test`) are a good example of directed tests in Python.
