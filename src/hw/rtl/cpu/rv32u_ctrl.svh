// SPDX-License-Identifier: Apache-2.0
// RV32u CPU types: YOURS, and optional (decisions D6, D7).
//
// This file is `include'd inside package rv32u_pkg (src/hw/rtl/rv32u_pkg.sv), so
// everything you declare here is rv32u_pkg::<name>. Put here any type more than one of
// your modules shares: your FSM's state enum, a packed struct of control signals from
// your control logic to your datapath, a struct of status signals back. (Yosys, Tiny
// Tapeout's synthesis tool, supports only one package and no imports, so shared types
// must live in rv32u_pkg; refer to them as rv32u_pkg::state_e and so on.)
//
// Leave it empty if you need no shared types. For example:
//
//   typedef enum logic [2:0] {S_FETCH, S_DECODE, ...} state_e;
//
//   typedef struct packed {
//     alu_op_e alu_op;   // the package's ALU operation encoding (optional too)
//     logic    pc_we;
//     ...
//   } ctrl_t;
