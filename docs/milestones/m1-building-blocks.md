# M1: Building blocks

You'll decide how your CPU is split into modules, build the blocks every instruction uses (register storage, arithmetic, immediates), write unit tests that prove them, and build a first memory subsystem for the CPU to run from.

## Before you start

- Read [ISA and architectural state](../spec/02-isa.md), [Microarchitecture](../spec/04-microarchitecture.md) and [Memory subsystem](../spec/07-memory-subsystem.md).
- Run `make setup` and `make check-env` ([Getting started](../guide/getting-started.md)).

Time: about 9 hours.

## Part 1: Choose your structure (D7)

Which modules will `rv32u_cpu` contain?

1. Read [A suggested structure](../spec/04-microarchitecture.md#a-suggested-structure). Sketch a block diagram of your CPU: its modules, and the signals between them.
2. Decide which of them you will build first. Most designs start with a register file, an ALU and an immediate generator, because they need no FSM and are easy to test alone.
3. Write a first version of D7 in `DESIGN.md`. It can change later.

You should see: a diagram where every port of `rv32u_cpu` is driven or used by some module.

## Part 2: The building blocks

1. Create a file for each block in `src/hw/rtl/cpu/`, for example `rv32u_regfile.sv`, `rv32u_alu.sv` and `rv32u_immgen.sv`. Add each to `rv32u_cpu.core` and to `info.yaml` `source_files`, before `rv32u_cpu.sv` (R4.1).
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

## Part 4: A first memory subsystem

The starter `rv32u_mem_ss` never answers a request, so the CPU you build in M2 would wait forever on its first fetch. Build a simple, complete one now; in M3 you replace its RAM with the one the chip will have.

1. Read [What is fixed](../spec/07-memory-subsystem.md#what-is-fixed) and the [requirements](../spec/07-memory-subsystem.md#requirements) R7.1-R7.5 again.
2. Write a RAM module with a synchronous read, from a flip-flop array ([A suggested structure](../spec/07-memory-subsystem.md#a-suggested-structure)). Keep `RAM_WORDS` at 512 for now: it is too big for the chip, but it simulates.
3. In `rv32u_mem_ss.sv`, write the bus slave around it: decode the address (RAM, unmapped, I/O), answer each request with `mem_ready` ([chapter 3](../spec/03-memory-bus.md#timing)), forward I/O requests to `io_*`, and write `ld_wdata` to the RAM whenever `ld_we` is high.
4. List your new files in `rv32u_mem_ss.core` and `info.yaml`, and run `make lint`.
5. Unit-test it: a cocotb test with `rv32u_mem_ss` as the top level that loads words through the loader port, then reads them back over the bus, and checks the unmapped region reads 0.

You should see: your test passes, and the read-back timing matches the diagrams in chapter 3.

## Finishing

You're done when:

- `make lint` is clean;
- unit tests for your building blocks and your memory subsystem pass (R9.1);
- `DESIGN.md` D7 has a first version.

Questions:

1. If your ALU gives "equal" and "less than" for every operation, what does that save the control logic when it executes a branch?
2. A register file that reads combinationally is ready in the same cycle; one that reads on the clock edge, like the SRAM, is not. What would that change in your FSM?

Submit: nothing yet; commit your work.

Next on the Course path: read [Control FSM](../spec/05-control-fsm.md) and [Retire port and traps](../spec/06-retire-and-trap.md).
