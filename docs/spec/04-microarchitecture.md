# 4. Microarchitecture

RV32u is a **multi-cycle** core: it breaks each instruction into single-cycle steps, holds intermediate results in registers between them, and finishes one instruction before it fetches the next. There is no pipeline, so there are no hazards. How you organise it inside is yours.

## What is fixed

Only the boundary. `rv32u_cpu` (`src/hw/rtl/cpu/rv32u_cpu.sv`) is the CPU's top module, and its ports are fixed, because `rv32u_soc` and the tests connect to them:

| Ports | Spec |
|---|---|
| `clk`, `rst_n` (synchronous, active low) | [chapter 5](05-control-fsm.md), R5.3 |
| the memory bus: `mem_valid`, `mem_ready`, `mem_addr`, `mem_wdata`, `mem_wstrb`, `mem_rdata` | [chapter 3](03-memory-bus.md) |
| `trap` | [chapter 6](06-retire-and-trap.md) |
| the retire port: `rvfi_*` | [chapter 6](06-retire-and-trap.md) |

Everything inside is your design (decisions D6-D8): which modules you write, what each one does, and how they talk to each other. It could all be one file. It probably shouldn't be: a split into small modules is easier to unit-test ([chapter 9](09-verification.md#your-unit-tests)), to read, and to debug.

- R4.1: every file you add must be listed in `src/hw/rtl/cpu/rv32u_cpu.core` and in `info.yaml` `source_files` (`make mem-check` checks the two lists agree).
- R4.2: `rv32u_cpu` keeps its name and its ports.

## A suggested structure

Most multi-cycle designs, including the one in Harris & Harris section 7.4, separate **what holds and moves data** from **what decides**:

| Module | Does |
|---|---|
| register file | 32 x 32-bit: two read ports, one write port; `x0` reads as zero |
| ALU | `ADD`, `SUB`, `AND`, `OR`, `SLT`, and the comparisons the branches need (equal, signed less-than) |
| immediate generator | the I, S, B, U and J immediates of an instruction |
| datapath | the PC and the registers between steps, the multiplexers, the memory request, the retire port |
| control | the FSM: the state register, the next-state logic, and the signals that steer the datapath |

The package offers encodings for the ALU operation (`rv32u_pkg::alu_op_e`) and the immediate format (`rv32u_pkg::imm_sel_e`) if you want them. Types your modules share, such as a state enum or a struct of control signals, go in `src/hw/rtl/cpu/rv32u_ctrl.svh` (it is `include`d inside `rv32u_pkg`, see R4.4).

Other splits work as well. A few:

- control and datapath merged into one module, with the register file, ALU and immediate generator as its sub-modules;
- a separate decoder, turning the instruction into a struct of fields the control logic and the datapath both read;
- a dedicated adder for PC + 4 and branch targets beside a smaller ALU (D8).

Whatever you choose, record it in `DESIGN.md` (D7).

The usual registers between steps, if you follow the classic design (you may add or drop non-architectural ones):

| Register | Holds | Typically written |
|---|---|---|
| `PC` | the address of the next instruction to fetch | when a fetch completes (PC + 4); by a taken branch, `JAL` and `JALR` |
| `OldPC` | the address of the instruction being executed | when a fetch completes |
| `IR` | the instruction being executed | when a fetch completes, from `mem_rdata` |
| `A`, `B` | `x[rs1]` and `x[rs2]`, read from the register file | after decode |
| `ALUOut` | the ALU result of the previous step (or a return address) | after any ALU step whose result is used later |
| `MDR` | the word loaded by `LW` | when the load completes, from `mem_rdata` |
| register file | `x1`-`x31` | when an instruction writes its result |

## SystemVerilog rules

The same RTL must work in three tools: Verilator and Icarus Verilog 12 (simulation) and Yosys (synthesis for Tiny Tapeout). Their common subset rules out a few things, so:

- R4.3: **No package imports.** Refer to package items as `rv32u_pkg::NAME` (`rv32u_pkg::ALU_ADD`, `rv32u_pkg::ctrl_t`). Yosys accepts one package, referred to by name; it rejects `import` in any position.
- R4.4: **One package.** Your shared CPU types live in `rv32u_ctrl.svh`, which is `` `include``'d inside `rv32u_pkg`. Do not create another package.
- R4.5: Assign struct fields one at a time (`assign status.insn = ir;`), not with a named assignment pattern (`'{insn: ...}`), which Icarus rejects.
- R4.6: A conditional between two enum values needs an explicit cast for Icarus: `state_next = rv32u_pkg::state_e'(c ? rv32u_pkg::S_ONE : rv32u_pkg::S_TWO);`.
- R4.7: Use `always_ff` for flip-flops and `always_comb` for logic. Give every `always_comb` output a default value at the top, so no latch is inferred.

`make lint` runs Verilator on the design as Tiny Tapeout builds it. The tests compile it with Verilator or Icarus, so a construct one tool rejects shows up quickly.

## Check yourself

1. Why does the multi-cycle core need `OldPC` as well as `PC`?

   <details><summary>Answer</summary>
   A fetch writes PC + 4 into the PC when it completes. But `AUIPC`, the branches and `JAL` compute their result from the address of the instruction itself (PC-relative), and by then it is gone from the PC. `OldPC` keeps it.
   </details>
