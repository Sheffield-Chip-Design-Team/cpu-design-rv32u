# M2: Datapath and FSM

You'll design the control interface (D6, D7, D8), build the datapath and the control FSM, and drive the retire port, until every per-instruction test passes in lockstep with the reference model.

## Before you start

- Finish [M1](m1-building-blocks.md).
- Read [Control FSM](../spec/05-control-fsm.md) and [Retire port and traps](../spec/06-retire-and-trap.md).

Time: about 12 hours.

## Part 1: Design on paper first (D6, D7, D8)

1. Design your states (D6): which states there are, what each one does, and the sequence each of the 14 instructions passes through ([chapter 5](../spec/05-control-fsm.md#where-to-start)). Then choose an encoding, and write `rv32u_pkg::state_e` in `src/hw/rtl/core/rv32u_ctrl.svh`.
2. List every control signal the datapath needs (D7): one per register write enable, plus multiplexer selects, the memory request and the retire pulses. Write them as fields of `ctrl_t`.
3. Decide the ALU's operand sources (D8). Check that every ALU operation your states perform is possible: PC + 4, PC-relative targets, A op B, A + immediate.
4. Fill in a table of every signal's value in every state, and put it in `DESIGN.md` (D7).

You should see: a table with one row per state, where every write enable is 0 unless your D6 description of that state writes the register. Trace two instructions (say `LW` and `BEQ`) through it by hand before you write any RTL.

## Part 2: The datapath

1. In `src/hw/rtl/core/rv32u_datapath.sv`, add the registers PC, OldPC, IR, MDR, A, B and ALUOut, each written only when its `ctrl` enable is high. Reset only the PC (to `rv32u_pkg::RESET_PC`).
2. Connect the register file, the ALU and the immediate generator, with the operand multiplexers from D8.
3. Drive the memory request from `ctrl`, following the [bus protocol](../spec/03-memory-bus.md).
4. Fill in `status`, and drive the retire port ([chapter 6](../spec/06-retire-and-trap.md)).

## Part 3: The FSM

1. In `src/hw/rtl/core/rv32u_control.sv`, write the next-state logic and every control signal, state by state, from your D7 table. Start every `always_comb` with defaults (`ctrl = '0;`).
2. Decode the instruction (`status.insn`) for the 14 instructions, and trap on anything else.
3. Run `make isa`. Start with `COCOTB_TEST_FILTER=lui make isa`: `LUI` needs the fewest steps.

You should see, once everything works:

```
** verif.test_isa.isa/program=add   PASS ...
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
