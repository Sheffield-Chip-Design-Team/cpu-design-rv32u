// SPDX-License-Identifier: Apache-2.0
// RV32u (RV32I-Micro) shared definitions: encodings, the ALU and immediate selectors,
// and the fixed memory map (spec: docs/spec/02-isa.md, 07-memory-subsystem.md).
//
// Provided: do not change the encodings or the memory map. The ALU and immediate
// selectors below are optional helpers: use them, change them or ignore them. Your own
// shared CPU types go in src/hw/rtl/cpu_ss/rv32u_ctrl.svh, `include'd at the end.
//
// Refer to anything here as rv32u_pkg::<name>. Do not `import rv32u_pkg::*`: Yosys,
// which Tiny Tapeout synthesises with, does not support package imports.

`default_nettype none

package rv32u_pkg;

  // ---- opcodes (inst[6:0]) -----------------------------------------------------------
  localparam logic [6:0] OP_LUI    = 7'b0110111;
  localparam logic [6:0] OP_AUIPC  = 7'b0010111;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD   = 7'b0000011;
  localparam logic [6:0] OP_STORE  = 7'b0100011;
  localparam logic [6:0] OP_IMM    = 7'b0010011;
  localparam logic [6:0] OP_REG    = 7'b0110011;

  // ---- funct3 / funct7 -----------------------------------------------------------------
  localparam logic [2:0] F3_ADD_SUB = 3'b000;  // ADD, SUB (OP_REG); ADDI (OP_IMM)
  localparam logic [2:0] F3_SLT     = 3'b010;
  localparam logic [2:0] F3_OR      = 3'b110;
  localparam logic [2:0] F3_AND     = 3'b111;
  localparam logic [2:0] F3_BEQ     = 3'b000;
  localparam logic [2:0] F3_BLT     = 3'b100;
  localparam logic [2:0] F3_WORD    = 3'b010;  // LW, SW
  localparam logic [2:0] F3_JALR    = 3'b000;

  localparam logic [6:0] F7_ZERO    = 7'b0000000;
  localparam logic [6:0] F7_SUB     = 7'b0100000;

  // ---- ALU operation (optional helper, for an ALU module if you have one) -------------
  typedef enum logic [2:0] {
    ALU_ADD = 3'd0,
    ALU_SUB = 3'd1,
    ALU_AND = 3'd2,
    ALU_OR  = 3'd3,
    ALU_SLT = 3'd4
  } alu_op_e;

  // ---- immediate format (optional helper, for an immediate generator) ----------------
  typedef enum logic [2:0] {
    IMM_I = 3'd0,
    IMM_S = 3'd1,
    IMM_B = 3'd2,
    IMM_U = 3'd3,
    IMM_J = 3'd4
  } imm_sel_e;

  // ---- memory map (fixed; spec 07-memory-subsystem.md) --------------------------------
  // RAM occupies [0, RAM_BYTES); the size comes from the memory option you choose
  // (decision D1) through the RAM_WORDS parameter of src/hw/rtl/mem_ss/rv32u_mem_ss.sv.
  localparam logic [31:0] RAM_BASE = 32'h0000_0000;
  localparam logic [31:0] IO_BASE  = 32'h8000_0000;  // addr[31] = 1: I/O region (D3)

  localparam logic [31:0] RESET_PC = 32'h0000_0000;

  // ---- your shared CPU types (optional; decisions D6, D7) ----------------------------
`include "rv32u_ctrl.svh"

endpackage
