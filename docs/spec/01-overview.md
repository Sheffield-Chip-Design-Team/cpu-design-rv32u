# 1. Overview

RV32u (RV32I-Micro) is a **multi-cycle** RISC-V core for a **14-instruction subset of RV32I**. The subset covers all six RISC-V instruction formats (R, I, S, B, U, J). It is enough for arithmetic, memory access, pointers and function calls, so the core runs real C compiled by GCC ([software flow](08-software-flow.md)). The hardware stays small: there is no shifter, no byte or halfword memory access, and one shared ALU.

You will:

1. implement the core from the provided skeletons, to the fixed parts of this specification;
2. make the design decisions D1 to D8 that the specification leaves open, and record them in `DESIGN.md`;
3. pass the provided tests: every instruction, then real C programs, each run in lockstep with a reference model;
4. integrate the core into a Tiny Tapeout IHP SG13CMOS5L chip with on-chip SRAM, and harden it with the Tiny Tapeout GDS action.

## How to read this specification

Each chapter states **requirements**. They use "must", and the provided tests check them. **Design decisions** are the parts that are yours. Each appears in a box like this one:

::: {.callout-important title="Design decision Dn: the name"}
**Decide:** what you have to choose.

**Constraints:** what any answer must satisfy.

**Options:** some ways to do it, with their trade-offs. Others are fine if they meet the constraints.

**Record in DESIGN.md (Dn):** what to write down.
:::

`make design-check` fails until every decision in `DESIGN.md` is answered.

## What is provided and what is yours

| Part | Files | Status |
|---|---|---|
| Encodings, ALU/immediate selectors, memory map | `src/rv32u_pkg.sv` | provided, fixed |
| Control interface types (states, control signals) | `src/hw/rtl/core/rv32u_ctrl.svh` | **yours** (D6, D7, D8) |
| Register file, ALU, immediate generator | `src/hw/rtl/core/rv32u_{regfile,alu,immgen}.sv` | **yours** (skeletons with ports) |
| Control FSM, datapath | `src/hw/rtl/core/rv32u_{control,datapath}.sv` | **yours** (skeletons with ports) |
| Core wiring | `src/hw/rtl/core/rv32u_core.sv` | provided |
| Memory subsystem, the three RAM options | `src/hw/rtl/mem_ss/` | provided (you choose one: D1) |
| I/O region, program loader | `src/io/` | **yours** (stubs: D2, D3, D4, D5) |
| System and Tiny Tapeout top level | `src/rv32u_soc.sv`, `src/tt_um_sharc_rv32u.sv` | provided (adapt the pin mapping: D5) |
| Reference model, ISA and C tests | `src/hw/dv/`, `src/sw/` | provided |
| Unit tests of your modules | `src/hw/dv/` (your files) | **yours** |
| Tiny Tapeout flow | `info.yaml`, `src/config.json`, `.github/workflows/` | provided |

## The design decisions

| | Decision | Chapter |
|---|---|---|
| D1 | Memory implementation: one 512x32 SRAM macro, two 512x16 macros, or flip-flops | [Memory subsystem](07-memory-subsystem.md) |
| D2 | Program loader: how a compiled program gets into the RAM on the chip | [Tiny Tapeout integration](10-tiny-tapeout.md) |
| D3 | I/O registers and their addresses | [Tiny Tapeout integration](10-tiny-tapeout.md) |
| D4 | How a finished program (or a trap) is signalled | [Tiny Tapeout integration](10-tiny-tapeout.md) |
| D5 | The pinout | [Tiny Tapeout integration](10-tiny-tapeout.md) |
| D6 | FSM states, their sequence per instruction, and their encoding | [Control FSM](05-control-fsm.md) |
| D7 | The control signals and their value in every state | [Control FSM](05-control-fsm.md) |
| D8 | ALU operand selection | [Control FSM](05-control-fsm.md) |

## Block diagram

```
                 Tiny Tapeout pins (ui, uo, uio)
                   |                       |
           +---------------+        +--------------+
           |  rv32u_loader |        |   rv32u_io   |   D2, D3, D4, D5
           |      (D2)     |        |  (D3, D4)    |
           +---------------+        +--------------+
             | core reset |  load        ^ I/O region (addr[31] = 1)
             v            v  port        |
      +-------------+   +--------------------------------+
      | rv32u_core  |   |           rv32u_mem            |
      |  control    |==>| valid/ready slave, decode      |
      |  datapath   |<==|   RAM  [0, RAM_BYTES)  ------> rv32u_ram: macro_512x32,
      +-------------+   |   I/O  addr[31] = 1            |   macro_2x512x16 or flops (D1)
        | retire port   +--------------------------------+
        v (verification only)
```

## Conventions

- Signals are active high unless they end in `_n`.
- Reset is synchronous and active low (`rst_n`).
- "Word" means 32 bits. Addresses are byte addresses.
- Register names: `x0`-`x31`, or their ABI names (`sp`, `ra`, `a0`, ...) in software.
