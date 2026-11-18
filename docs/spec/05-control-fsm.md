# 5. Control FSM

The control unit is a finite-state machine that steps the datapath through each instruction. **Its states are yours to design**: how many there are, what each one does, the order an instruction passes through them, and how they are encoded (D6), as are the CPU's modules (D7) and its arithmetic (D8). The specification fixes only what the core does at its boundary: the instructions it executes ([chapter 2](02-isa.md)), the memory bus protocol ([chapter 3](03-memory-bus.md)), and the retire port and trap rule ([chapter 6](06-retire-and-trap.md)).

## What is required

- R5.1, **retirement equivalence:** the sequence of instructions your core retires, and every value it reports for each one, must equal the reference model's ([chapter 9](09-verification.md)). This is all the provided tests check.
- R5.2, **multi-cycle:** one instruction at a time. An instruction retires before the next one is fetched, and the core uses the one memory bus for both fetches and data (no pipeline, no caches, no separate instruction memory).
- R5.3, **reset:** after reset, the first bus request is a fetch from address `0x0000_0000`.
- R5.4, **progress:** with your memory subsystem, every instruction must retire within 200 cycles of the previous one (the tests treat a longer gap as a hang).

How many cycles each instruction takes is **not** checked. It is your design's performance: measure it, and record it in `DESIGN.md` (D6). The tests print it: `make isa` reports each program's cycles, and `make c` each program's cycles per instruction (CPI).

## Where to start

A multi-cycle core usually splits an instruction into steps of the kind below, one ALU operation or one memory access each, with the result held in a register between steps ([chapter 4](04-microarchitecture.md)):

- **fetch** the instruction at the PC, and compute PC + 4;
- **decode** it, and read its source registers;
- **execute**: an ALU operation, an effective address, a branch comparison or a jump target;
- **access memory**, for `LW` and `SW`;
- **write back** the result to the register file.

Not every instruction needs every step, and steps can be merged or split. For example, a branch can finish once it has compared its operands, and the branch target can be computed early, in a cycle where the ALU is otherwise idle. Harris & Harris, *Digital Design and Computer Architecture: RISC-V Edition*, section 7.4, derives one such design ([Resources](../guide/resources.md)). Theirs is a good starting point, but it is not the required answer.

Wait states come on top. A memory access lasts until `mem_ready` ([chapter 3](03-memory-bus.md)), so with a one-wait-state RAM every fetch and every `LW`/`SW` takes at least two cycles.

::: {.callout-note title="Changes from the original RV32I-Micro note"}
- The original note listed a fixed set of states and cycle counts. Here they are your design; only the retired instructions are checked.
- `SW` computes its address with the S-type immediate (`imm_s`). The original note gave `imm_i` for both `LW` and `SW`, but they are different formats.
- The trap rule ([chapter 6](06-retire-and-trap.md)) is new: the core stops on anything it cannot execute.
:::

## Design decisions

::: {.callout-important title="Design decision D6: states and their encoding"}
**Decide:** your FSM's states, what each one does, the sequence each instruction passes through, and how the states are encoded in `rv32u_pkg::state_e` (`src/hw/rtl/cpu/rv32u_ctrl.svh`).

**Constraints:** R5.1-R5.4 above, the [bus protocol](03-memory-bus.md) (a state that makes a request waits in place until `mem_ready`), and the [trap rule](06-retire-and-trap.md) (the core stops for good). Reset must enter a defined state, and any unused encoding must lead somewhere safe.

**Options:**

- *The state set:* fewer states give a lower CPI but put more work, and longer paths, into each cycle. More states give shorter paths, so a faster clock is possible, but a higher CPI.
- *Sharing states between instructions:* sharing gives a smaller FSM. A dedicated state for an instruction (for example `JAL`) can make that instruction faster or its control simpler.
- *The encoding:* binary (the fewest flip-flops, more decode logic); one-hot (one flip-flop per state, trivial decode, the fastest next-state logic); Gray or hand-picked codes (fewer bits flip on common transitions).

**Record in DESIGN.md (D6):** a state diagram or table: every state, what it does and its next states. Then each state's encoding, and the cycles each instruction class takes with your memory subsystem (from `make isa`), with your reasons.
:::

::: {.callout-important title="Design decision D7: module structure and control"}
**Decide:** how `rv32u_cpu` is split into modules, what each one does, and the signals between them. If you separate control from the datapath, that includes every control signal and its value in every state (and, where it differs, for every instruction in that state).

**Constraints:** the ports of `rv32u_cpu` are fixed ([chapter 4](04-microarchitecture.md#what-is-fixed)). A register may change only when your control logic decides it should. Memory requests must follow the [bus protocol](03-memory-bus.md), and the retire port must pulse exactly as [chapter 6](06-retire-and-trap.md) says. The RTL must stay in the tools' common subset (R4.3-R4.7).

**Options:**

- *The split:* the classic control + datapath + register file, ALU and immediate generator ([chapter 4](04-microarchitecture.md#a-suggested-structure)); a separate decoder; fewer, larger modules; or one module. Smaller modules are easier to unit-test and to reason about; every extra boundary is another interface to keep consistent.
- *The control signals:* one write enable per register with separate multiplexer selects, collected in a packed struct (`rv32u_ctrl.svh`); or fewer, wider "micro-operations" decoded where they are used. More signals give a simpler datapath and a more readable table; fewer give a smaller interface.

**Record in DESIGN.md (D7):** your modules and what each does (a block diagram helps), the interfaces between them, and, if you have a control/datapath split, the control signals with a table of their values per state.
:::

::: {.callout-important title="Design decision D8: arithmetic resources"}
**Decide:** which adders and ALUs the CPU has, and what feeds each one in each state. For example: one shared ALU with operand A from {A, PC, OldPC} and operand B from {B, immediate, 4}; or an ALU plus a separate adder for PC + 4 and branch targets.

**Constraints:** every arithmetic step your states perform must be possible. Across the 14 instructions that includes PC + 4, PC-relative targets (`AUIPC`, the branches, `JAL`), `A op B`, and `A` + an immediate (`ADDI`, `JALR`, `LW`, `SW`).

**Options:** one shared ALU with wide operand multiplexers (the least arithmetic, more multiplexing and possibly more states); smart reuse (e.g. keeping PC + 4 in a register); dedicated adders (more area, fewer states or shorter paths).

**Record in DESIGN.md (D8):** each adder or ALU, the sources of its operands and when each is selected, and why.
:::

## Check yourself

1. A design computes a branch's target speculatively, in a cycle where the ALU is otherwise idle, before it knows whether the instruction is a branch. Why is that safe?

   <details><summary>Answer</summary>
   It only writes a non-architectural register (such as `ALUOut`), which a non-branch instruction overwrites before it uses it. Doing it unconditionally saves decoding the opcode first, and lets a branch finish as soon as it has compared its operands.
   </details>

2. Two designs pass every test: one takes 4 cycles for `ADD`, the other 5. Why might the 5-cycle one still be the better chip?

   <details><summary>Answer</summary>
   Time per instruction is cycles x clock period. If its extra state shortens the longest path enough to raise the clock frequency by more than 25%, the 5-cycle design finishes programs sooner. It may also be smaller. That trade-off is exactly what D6 records.
   </details>
