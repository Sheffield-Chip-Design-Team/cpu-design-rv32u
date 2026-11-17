# 4. Microarchitecture

RV32u breaks each instruction into **single-cycle steps**. Each step does one ALU operation or one memory access, and the result is held in a register between steps. There is **one ALU**, shared by every step: it computes PC + 4, branch and jump targets, effective addresses and every R- and I-type result. There is no pipeline, so there are no hazards: an instruction finishes before the next one is fetched.

## Registers

The architectural registers (the PC and `x0`-`x31`) and the usual non-architectural registers between steps. When each is written depends on your states (D6). You may add or drop non-architectural registers, if you record why in `DESIGN.md` (D7).

| Register | Holds | Typically written |
|---|---|---|
| `PC` | the address of the next instruction to fetch | when a fetch completes (PC + 4); by a taken branch, `JAL` and `JALR` |
| `OldPC` | the address of the instruction being executed | when a fetch completes |
| `IR` | the instruction being executed | when a fetch completes, from `mem_rdata` |
| `A`, `B` | `x[rs1]` and `x[rs2]`, read from the register file | after decode |
| `ALUOut` | the ALU result of the previous step (or a return address) | after any ALU step whose result is used later |
| `MDR` | the word loaded by `LW` | when the load completes, from `mem_rdata` |
| register file | `x1`-`x31` | when an instruction writes its result |

## Module structure

The skeleton fixes the module boundaries and their ports. The insides are yours.

| Module | Does | Interface |
|---|---|---|
| `rv32u_regfile` | 32 x 32-bit registers: two combinational read ports, one write port (on the clock edge, when `we`) | addresses, data |
| `rv32u_alu` | `y = a op b` for `op` in `ADD, SUB, AND, OR, SLT`; `eq = (a == b)` and `lt = (a < b, signed)`, whatever `op` is | `rv32u_pkg::alu_op_e` |
| `rv32u_immgen` | the I/S/B/U/J immediate of `insn` | `rv32u_pkg::imm_sel_e` |
| `rv32u_control` | the FSM: the state register, the next-state logic, and every control signal | `ctrl_t` out, `status_t` in |
| `rv32u_datapath` | the registers above, the operand multiplexers, the memory request, the retire port | `ctrl_t` in, `status_t` out |
| `rv32u_cpu_ss` | wires control and datapath together (provided) | the memory bus, the retire port, `trap` |

`ctrl_t` and `status_t` are packed structs that you define in `src/hw/rtl/cpu_ss/rv32u_ctrl.svh` (decision [D7](05-control-fsm.md)). The control unit and the datapath see the same definitions, so they cannot disagree. `status_t` comes with the fields the control unit needs (the IR, `mem_ready`, the ALU flags and the misalignment checks). Add more if your control needs them.

## SystemVerilog rules

The same RTL must work in three tools: Verilator and Icarus Verilog 12 (simulation) and Yosys (synthesis for Tiny Tapeout). Their common subset rules out a few things, so:

- R4.1: **No package imports.** Refer to package items as `rv32u_pkg::NAME` (`rv32u_pkg::ALU_ADD`, `rv32u_pkg::ctrl_t`). Yosys accepts one package, referred to by name; it rejects `import` in any position.
- R4.2: **One package.** Your control types live in `rv32u_ctrl.svh`, which is `` `include``'d inside `rv32u_pkg`. Do not create another package.
- R4.3: Assign struct fields one at a time (`assign status.insn = ir;`), not with a named assignment pattern (`'{insn: ...}`), which Icarus rejects.
- R4.4: A conditional between two enum values needs an explicit cast for Icarus: `state_next = rv32u_pkg::state_e'(c ? rv32u_pkg::S_ONE : rv32u_pkg::S_TWO);`.
- R4.5: Use `always_ff` for flip-flops and `always_comb` for logic. Give every `always_comb` output a default value at the top, so no latch is inferred.

`make lint` runs Verilator on the design as Tiny Tapeout builds it. The tests compile it with Verilator or Icarus, so a construct one tool rejects shows up quickly.

## Check yourself

1. Why does the multi-cycle core need `OldPC` as well as `PC`?

   <details><summary>Answer</summary>
   A fetch writes PC + 4 into the PC when it completes. But `AUIPC`, the branches and `JAL` compute their result from the address of the instruction itself (PC-relative), and by then it is gone from the PC. `OldPC` keeps it.
   </details>
