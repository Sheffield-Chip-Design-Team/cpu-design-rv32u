# M1: Building blocks

You'll implement the three combinational and storage blocks every instruction uses: the register file, the ALU and the immediate generator. Then you'll write unit tests that prove them before anything depends on them.

## Before you start

- Read [ISA and architectural state](../spec/02-isa.md) and [Microarchitecture](../spec/04-microarchitecture.md).
- Run `make setup` and `make check-env` ([Getting started](../guide/getting-started.md)).

Time: about 6 hours.

## Part 1: The register file

What does a two-read, one-write register file with a hardwired `x0` look like in SystemVerilog?

1. Open `src/hw/rtl/cpu_ss/rv32u_regfile.sv`. Keep the ports; replace the `TODO` and the tied-off outputs.
2. Store `x1`-`x31` and write on the rising edge when `we` is high. Read both ports combinationally.
3. Make `x0` read as zero whatever is written to it.
4. Run `make lint`.

You should see: `make lint` finishes with no `%Error` or `%Warning` lines for `rv32u_regfile`.

## Part 2: The ALU and the immediate generator

1. In `src/hw/rtl/cpu_ss/rv32u_alu.sv`, compute `y` for each `rv32u_pkg::alu_op_e`, and the flags `eq` and `lt` (signed) for every `op`.
2. In `src/hw/rtl/cpu_ss/rv32u_immgen.sv`, produce the five immediates from [chapter 2](../spec/02-isa.md#immediates).
3. Refer to package items as `rv32u_pkg::ALU_ADD` and so on: no `import` (R4.1).

Before you run anything, predict: what is `y` for `ALU_SLT` with `a = 32'h8000_0000`, `b = 1`?

<details><summary>Answer</summary>
1: `0x8000_0000` is the most negative 32-bit number, so it is less than 1 as a signed comparison.
</details>

## Part 3: Unit tests (required)

The whole-core tests will not tell you which block is wrong, so test each block alone ([chapter 9](../spec/09-verification.md#your-unit-tests)).

1. Create `src/hw/dv/unit/__init__.py` (empty) and `src/hw/dv/unit/test_alu.py` with cocotb tests: every operation, overflow, and signed compares at the extremes.
2. Add a `unit_alu` target to `src/hw/dv/rv32u_tb.core` (the example is in chapter 9) and run it with `uv run fusesoc --cores-root src/hw --cores-root ip run --no-export --target=unit_alu sharc:rv32u:tb`.
3. Do the same for the register file (including `x0`, and writing then reading every register) and the immediate generator (every format, positive and negative).

You should see: every unit test passes, and breaking one line of your ALU makes at least one of them fail.

## Finishing

You're done when:

- `make lint` is clean;
- unit tests for the register file, the ALU and the immediate generator pass.

Questions:

1. Why does the ALU produce `eq` and `lt` for every operation, instead of only when `op` is `ALU_SLT`?
2. Your register file reads combinationally. What would change in the FSM if it read on the clock edge, like the SRAM?

Submit: nothing yet; commit your work.

Next on the Course path: read [Control FSM](../spec/05-control-fsm.md) and [Retire port and traps](../spec/06-retire-and-trap.md).
