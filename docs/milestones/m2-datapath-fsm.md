# M2: Datapath and FSM

You'll design the control interface (D6, D7, D8), build the datapath and the control FSM, and drive the retire port, until every per-instruction test passes in lockstep with the reference model.

## Before you start

- Finish [M1](m1-building-blocks.md).
- Read [Control FSM](../spec/05-control-fsm.md) and [Retire port and traps](../spec/06-retire-and-trap.md).
- Finish M1 Part 4: the CPU needs your first memory subsystem to fetch from.

Time: about 12 hours.

## Part 1: Design on paper first (D6, D7, D8)

1. Design your states (D6): which states there are, what each one does, and the sequence each of the 14 instructions passes through ([chapter 5](../spec/05-control-fsm.md#where-to-start)). Then choose an encoding.
2. Finish your structure (D7): where the state register lives, which module decides each step, and the signals that carry those decisions. If you separate control from the datapath, list every control signal (register write enables, multiplexer selects, the memory request, the retire pulse); a packed struct in `src/hw/rtl/cpu/rv32u_ctrl.svh` keeps both sides in agreement.
3. Decide your arithmetic (D8): one shared ALU, or more adders. Check that every arithmetic step your states perform is possible: PC + 4, PC-relative targets, A op B, A + immediate.
4. Write a table of what happens in every state (which registers are written, from what), and put it in `DESIGN.md` (D7).

You should see: a table with one row per state, where nothing is written unless your D6 description of that state writes it. Trace two instructions (say `LW` and `BEQ`) through it by hand before you write any RTL.

## Part 2: Build the CPU

1. Write the modules of your D7 structure in `src/hw/rtl/cpu/`, and instantiate them in `rv32u_cpu.sv` in place of the starter's tied-off outputs. List new files in `rv32u_cpu.core` and `info.yaml` (R4.1).
2. The registers between steps change only when a state says so. Reset the PC to `rv32u_pkg::RESET_PC`.
3. Drive the memory request following the [bus protocol](../spec/03-memory-bus.md), and the retire port and `trap` following [chapter 6](../spec/06-retire-and-trap.md).
4. Decode the 14 instructions, and trap on anything else. Start every `always_comb` with defaults, so nothing is latched (R4.7).
5. Run `make isa`. Start with `COCOTB_TEST_FILTER=lui make isa`: `LUI` needs the fewest steps.

You should see, once everything works:

```
** dv.test_isa.isa/program=add   PASS ...
...
** TESTS=19 PASS=19 FAIL=0 SKIP=0 ...
```

If a test fails, read its message ([chapter 9](../spec/09-verification.md#reading-a-failure)). It names the first instruction that differs from the model, and how.

## Finishing

You're done when:

- `make isa` passes all 19 tests;
- `DESIGN.md` D6, D7 and D8 are answered, with the cycles each instruction class takes (from the `make isa` log).

Questions:

1. Which instructions' cycle counts would change if your memory had two wait states instead of one? By how much?
2. Where in your design does a branch decide whether it is taken? How many cycles would you save, or lose, by computing its target in a different state?

Submit: commit your work.

Next on the Course path: read [Memory subsystem](../spec/07-memory-subsystem.md), [Software flow](../spec/08-software-flow.md) and [Verification](../spec/09-verification.md).
