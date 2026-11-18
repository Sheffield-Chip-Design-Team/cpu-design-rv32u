# M1: Building blocks

You'll decide how your CPU is split into modules, build the blocks every instruction uses (register storage, arithmetic, immediates), and write unit tests that prove them before anything depends on them.

## Before you start

- Read [ISA and architectural state](../spec/02-isa.md) and [Microarchitecture](../spec/04-microarchitecture.md).
- Run `make setup` and `make check-env` ([Getting started](../guide/getting-started.md)).

Time: about 6 hours.

## Part 1: Choose your structure (D7)

Which modules will `rv32u_cpu_ss` contain?

1. Read [A suggested structure](../spec/04-microarchitecture.md#a-suggested-structure). Sketch a block diagram of your CPU: its modules, and the signals between them.
2. Decide which of them you will build first. Most designs start with a register file, an ALU and an immediate generator, because they need no FSM and are easy to test alone.
3. Write a first version of D7 in `DESIGN.md`. It can change later.

You should see: a diagram where every port of `rv32u_cpu_ss` is driven or used by some module.

## Part 2: The building blocks

1. Create a file for each block in `src/hw/rtl/cpu_ss/`, for example `rv32u_regfile.sv`, `rv32u_alu.sv` and `rv32u_immgen.sv`. Add each to `rv32u_cpu_ss.core` and to `info.yaml` `source_files`, before `rv32u_cpu_ss.sv` (R4.1).
2. Register file: 32 x 32-bit, two read ports and one write port; `x0` reads as zero whatever is written to it.
3. ALU: `ADD`, `SUB`, `AND`, `OR`, `SLT`, plus what your branches need (equal, signed less-than). You may use the package's `rv32u_pkg::alu_op_e`, or your own encoding.
4. Immediates: the five formats from [chapter 2](../spec/02-isa.md#immediates).
5. Refer to package items as `rv32u_pkg::NAME`: no `import` (R4.3). Run `make lint`.

Before you run anything, predict: what is the signed comparison `0x8000_0000 < 1`?

<details><summary>Answer</summary>
True: `0x8000_0000` is the most negative 32-bit number, so `SLT` gives 1.
</details>

You should see: `make lint` finishes with no `%Error` or `%Warning` lines for your new files.

## Part 3: Unit tests (required)

The whole-CPU tests will not tell you which block is wrong, so test each block alone ([chapter 9](../spec/09-verification.md#your-unit-tests)).

1. Create `src/hw/dv/unit/__init__.py` (empty) and a cocotb test per block, for example `src/hw/dv/unit/test_alu.py`: every operation, overflow, and signed compares at the extremes.
2. Add a target for it to `src/hw/dv/rv32u_tb.core` (the example is in chapter 9) and run it with `uv run fusesoc --cores-root src/hw --cores-root ip run --no-export --target=unit_alu sharc:rv32u:tb`.
3. Cover the register file (including `x0`, and writing then reading every register) and every immediate format, positive and negative.

You should see: every unit test passes, and breaking one line of a block makes at least one of them fail.

## Finishing

You're done when:

- `make lint` is clean;
- unit tests for your building blocks pass (R9.1);
- `DESIGN.md` D7 has a first version.

Questions:

1. If your ALU gives "equal" and "less than" for every operation, what does that save the control logic when it executes a branch?
2. A register file that reads combinationally is ready in the same cycle; one that reads on the clock edge, like the SRAM, is not. What would that change in your FSM?

Submit: nothing yet; commit your work.

Next on the Course path: read [Control FSM](../spec/05-control-fsm.md) and [Retire port and traps](../spec/06-retire-and-trap.md).
