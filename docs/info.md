<!---
This file generates the Tiny Tapeout datasheet (.github/workflows/docs.yaml). Fill it in
for your design (decisions D2-D5) before submission. Each image must be under 512 kB,
and all images together under 1 MB.
-->

## How it works

RV32u is a multi-cycle RISC-V core for a 14-instruction subset of RV32I (`LUI`, `AUIPC`, `JAL`, `JALR`, `BEQ`, `BLT`, `LW`, `SW`, `ADDI`, `ADD`, `SUB`, `AND`, `OR`, `SLT`), with on-chip RAM for its program, data and stack.

_TODO(D1): the RAM option and its size._

_TODO(D3): the I/O registers and their addresses._

## How to test

_TODO(D2): how to load a program (the loader's pins and protocol), and how to start the core._

_TODO(D4): how to tell when the program has finished, or trapped._

## External hardware

_TODO: anything beyond the Tiny Tapeout demo board (the RP2040 on it can act as the loader host)._
