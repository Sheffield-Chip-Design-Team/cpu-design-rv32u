# CPU Design Mini-Project - RV32u

Design, verify and tape out a 14-instruction multi-cycle RISC-V core on Tiny Tapeout IHP.

You'll build **RV32u**, a multi-cycle core for a 14-instruction subset of RV32I (RV32I-Micro). It runs real C compiled with GCC, and you'll take it to a Tiny Tapeout IHP SG13CMOS5L chip with on-chip SRAM. The infrastructure is provided: the memory subsystem, the Tiny Tapeout flow, the toolchain scripts, a Python reference model and the tests. You design the core, and you make the design decisions the [specification](spec/01-overview.md) leaves open.

- Who it's for: students and team members who know digital logic and some Verilog, and want to build a CPU end to end.
- Prerequisites: combinational and sequential logic, finite-state machines, basic Verilog or SystemVerilog, and the command line. Some C helps.
- Total time: about 40 hours, the sum of the times in the course path (one focused week).

This site holds the specification and the milestone writeups. The code is in the project's [GitHub repo](https://github.com/Sheffield-Chip-Design-Team/rv32i-micro). The site is published to the repo's GitHub Pages, and so is the chip: the [layout viewer](viewer/index.html) opens the latest Tiny Tapeout GDS build in the Tiny Tapeout 3D viewer, with a [2D render](viewer/gds_render.png) beside it. (Both appear after the first successful `gds` workflow run on `main`.)

## Course path

Work down the table in order. A Read row points you to specification or guide pages, which are for reading only. A Do row is a milestone, where you build part of the core, run the tests and record your design decisions.

| # | | What | Time |
|---|---|---|---|
| 1 | Read | [Getting started](guide/getting-started.md) · [The flow](guide/flow.md) · [Specification overview](spec/01-overview.md) | 90 min |
| 2 | Read | [ISA and architectural state](spec/02-isa.md) · [Memory bus](spec/03-memory-bus.md) · [Microarchitecture](spec/04-microarchitecture.md) | 120 min |
| 3 | Do | [M1: Building blocks](milestones/m1-building-blocks.md). Implement the register file, ALU and immediate generator, and write unit tests for them. | 6 h |
| 4 | Read | [Control FSM](spec/05-control-fsm.md) · [Retire port and traps](spec/06-retire-and-trap.md) | 90 min |
| 5 | Do | [M2: Datapath and FSM](milestones/m2-datapath-fsm.md). Design the control interface (D6-D8), build the datapath and FSM, and pass every per-instruction test. | 12 h |
| 6 | Read | [Memory subsystem](spec/07-memory-subsystem.md) · [Software flow](spec/08-software-flow.md) · [Verification](spec/09-verification.md) | 90 min |
| 7 | Do | [M3: Running C](milestones/m3-running-c.md). Choose the memory (D1), run the C programs and write one of your own. | 6 h |
| 8 | Read | [Tiny Tapeout integration](spec/10-tiny-tapeout.md) · [Deliverables and acceptance](spec/11-deliverables.md) | 60 min |
| 9 | Do | [M4: Chip integration](milestones/m4-chip.md). Design the loader and I/O (D2-D5), harden the chip with the GDS action, and finish DESIGN.md. | 10 h |

Look things up in [Resources](guide/resources.md) as you go.
