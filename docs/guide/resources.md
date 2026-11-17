# Resources

Where to learn what this mini-project assumes, and where to look when you are stuck. The starred items are the ones to read first.

## RISC-V

- ★ [The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA](https://riscv.org/specifications/ratified/): chapter "RV32I Base Integer Instruction Set" defines every instruction RV32u implements. Also on [GitHub](https://github.com/riscv/riscv-isa-manual/releases).
- ★ [RISC-V reference card](https://github.com/jameslzhu/riscv-card): every encoding on two pages.
- *The RISC-V Reader: An Open Architecture Atlas*, Patterson and Waterman: a short, readable tour of the ISA and the reasons behind it.
- [RISC-V ABI specification](https://github.com/riscv-non-isa/riscv-elf-psabi-doc): register names (`a0`, `sp`, `ra` ...) and the calling convention the C programs use.
- [Compiler Explorer](https://godbolt.org) (choose "RISC-V rv32gc gcc" and add `-march=rv32i -mabi=ilp32 -O0`): see what your C becomes.
- [Ripes](https://github.com/mortbopet/Ripes): a graphical RISC-V simulator with single-cycle and pipelined processor views. Good for stepping through a program and watching the datapath.

## CPU design

- ★ Harris and Harris, *Digital Design and Computer Architecture: RISC-V Edition* (Morgan Kaufmann, 2021). Chapter 7 builds a single-cycle, a **multi-cycle** (section 7.4) and a pipelined RISC-V processor in SystemVerilog. RV32u's datapath is close to their multi-cycle one.
- Patterson and Hennessy, *Computer Organization and Design: RISC-V Edition*, chapter 4: the processor, from datapath to pipelining.
- [Onur Mutlu's Digital Design and Computer Architecture lectures (ETH Zurich)](https://safari.ethz.ch/digitaltechnik/): free lecture videos and slides that follow Harris and Harris.

Open cores to read (all small, all RV32I or a subset):

- [FemtoRV and "From Blinker to RISC-V"](https://github.com/BrunoLevy/learn-fpga/tree/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV): a step-by-step tutorial that grows a multi-cycle RV32I core from nothing.
- [PicoRV32](https://github.com/YosysHQ/picorv32): a size-optimised multi-cycle core, with a valid/ready memory interface much like RV32u's.
- [SERV](https://github.com/olofk/serv): a bit-serial RV32I core, the smallest there is, and a FuseSoC project.
- [TinyQV](https://github.com/MichaelBell/tinyQV): a RISC-V microcontroller built for Tiny Tapeout.
- [Ibex](https://github.com/lowRISC/ibex): an industrial-quality 2-stage core, with excellent documentation.

## SystemVerilog

- ★ [HDLBits](https://hdlbits.01xz.net): short exercises with instant feedback, from gates to FSMs.
- [ChipVerify SystemVerilog tutorial](https://www.chipverify.com/systemverilog/systemverilog-tutorial): language reference with examples.
- ★ [lowRISC Verilog coding style guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md): how to write synthesisable SystemVerilog that others can read.
- Clifford Cummings' papers at [Sunburst Design](http://www.sunburst-design.com/papers/), especially "Nonblocking Assignments in Verilog Synthesis, Coding Styles That Kill!" and "The Fundamentals of Efficient Synthesizable Finite State Machine Design".
- Sutherland, Davidmann and Flake, *SystemVerilog for Design*: the synthesisable subset in depth.
- [Verilator manual](https://verilator.org/guide/latest/): including what each lint warning means.

## Verification and the flow

- ★ [cocotb documentation](https://docs.cocotb.org/en/stable/): writing Python testbenches. Start with the "Quickstart" and "Writing Testbenches".
- [FuseSoC documentation](https://fusesoc.readthedocs.io/en/stable/): `.core` files and targets.
- [RISC-V Formal Interface (RVFI)](https://github.com/YosysHQ/riscv-formal/blob/main/docs/rvfi.md): the retire port RV32u's `rvfi_*` signals are modelled on.
- [riscv-tests](https://github.com/riscv-software-src/riscv-tests): the official per-instruction tests (for full RV32I).
- [GTKWave](https://gtkwave.sourceforge.net) and [Surfer](https://surfer-project.org): waveform viewers.
- [WaveDrom](https://wavedrom.com/tutorial.html): the timing-diagram language this site's bus diagrams are written in.

## Tiny Tapeout and the IHP process

- ★ [Tiny Tapeout](https://tinytapeout.com): how a project goes from a GitHub repo to a chip, the pinout, and the demo board.
- [Tiny Tapeout IHP SRAM example](https://github.com/TinyTapeout/ttihp-cmos5l-sram-example): the SRAM macro integration this project's flow is based on.
- [IHP SG13G2 SRAM macros](https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/reference_libraries/sram.html): the macros' sizes, ports and timing.
- [IHP-Open-PDK](https://github.com/IHP-GmbH/IHP-Open-PDK): the open process design kit.
- [LibreLane documentation](https://librelane.readthedocs.io): the RTL-to-GDS flow the GDS action runs.
