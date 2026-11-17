// SPDX-License-Identifier: Apache-2.0
// RV32u ALU: the one shared ALU of the multi-cycle datapath (spec 04-microarchitecture.md).
// It computes PC + 4, branch and jump targets, effective addresses and every R/I-type
// result. eq and lt always compare a and b, whatever op is.
//
// YOURS TO IMPLEMENT. Write a unit test for it (spec 09-verification.md).

`default_nettype none

module rv32u_alu (
    input  rv32u_pkg::alu_op_e     op,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y,   // ADD, SUB, AND, OR, SLT (1 if a < b signed, else 0)
    output logic        eq,  // a == b
    output logic        lt   // a <  b, signed
);

  // TODO(spec 04): y for each alu_op_e, and the two comparison flags.
  assign y  = 32'd0;
  assign eq = 1'b0;
  assign lt = 1'b0;

  wire _unused = &{1'b0, op, a, b};

endmodule
