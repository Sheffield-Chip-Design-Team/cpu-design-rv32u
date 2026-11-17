# 6. Retire port and traps

## The retire port

The core reports every instruction it completes on a **retire port**. Its signals are named after the RISC-V Formal Interface (RVFI). It exists for verification only: the provided tests compare it, instruction by instruction, with a reference model ([chapter 9](09-verification.md)). It is not connected to the chip's pins.

| Signal | Width | Meaning in the retire cycle |
|---|---|---|
| `rvfi_valid` | 1 | high for exactly one cycle per completed instruction |
| `rvfi_trap` | 1 | the instruction trapped |
| `rvfi_pc` | 32 | the address of the instruction |
| `rvfi_insn` | 32 | the instruction word (0 for a misaligned-fetch trap) |
| `rvfi_pc_next` | 32 | the PC after it: the next instruction's address (for a trap: `rvfi_pc`) |
| `rvfi_rd_addr` | 5 | the register written, or 0 if none (including writes to `x0`) |
| `rvfi_rd_wdata` | 32 | the value written, or 0 if `rvfi_rd_addr` is 0 |
| `rvfi_mem_addr` | 32 | `LW`/`SW`: the address accessed |
| `rvfi_mem_wstrb` | 4 | `SW`: `4'b1111`; otherwise 0 |
| `rvfi_mem_wdata` | 32 | `SW`: the word written |
| `rvfi_mem_rdata` | 32 | `LW`: the word read |

- R6.1: `rvfi_valid` is high for **exactly one cycle per instruction**, in or after the cycle whose rising edge commits the instruction's last change (its register write, its memory write or its PC update), and before the next instruction retires. All the other `rvfi_*` signals are valid in that cycle. Which state that is depends on your FSM (D6).
- R6.2: instructions retire in program order, one at a time.
- R6.3: no `rvfi_*` signal may be X or Z in a retire cycle. The memory fields are checked only for `LW` and `SW`; for other instructions their values do not matter.

## The trap rule

RV32u has no exceptions or interrupts. Instead, anything it cannot execute **stops the core**:

- R6.4: **illegal instruction.** An encoding that is not one of the 14 (chapter 2) traps as soon as it is decoded, before it changes any architectural state.
- R6.5: **misaligned fetch.** A fetch from a PC with `PC[1:0] != 0` traps instead of being fetched: no bus request is made. The trap retires with `rvfi_pc` = that PC and `rvfi_insn = 0`. A jump or branch to a misaligned address therefore completes normally, and the trap is reported at its target.
- R6.6: **misaligned access.** An `LW` or `SW` whose address has `addr[1:0] != 0` traps before its memory request: no memory is accessed, and no register is written.
- R6.7: a trap retires once (with `rvfi_trap = 1`), and then the core retires nothing more. The core makes no more bus requests, and the `trap` output stays high until reset.

Software ends a program in a self-loop instead: `halt: beq x0, x0, halt` (in the provided `crt0`). The tests stop when an instruction's `rvfi_pc_next` equals its `rvfi_pc`.

## Check yourself

1. `sw x5, 2(x6)` traps. What does the retire port show, and what is written to memory?

   <details><summary>Answer</summary>
   One retire with `rvfi_trap = 1` and `rvfi_pc` = the address of the `sw`. Nothing is written: the trap happens before the memory request (R6.6). After that, `rvfi_valid` never rises again until reset.
   </details>
