// SPDX-License-Identifier: Apache-2.0
// RV32u immediate generator: the five immediate formats, sign-extended from inst[31]
// (spec 02-isa.md, "Immediates").
//
// YOURS TO IMPLEMENT. Write a unit test for it (spec 09-verification.md).

`default_nettype none

module rv32u_immgen (
    input  logic [31:0] insn,
    input  rv32u_pkg::imm_sel_e    sel,
    output logic [31:0] imm
);

  // TODO(spec 02): I, S, B, U and J immediates.
  assign imm = 32'd0;

  wire _unused = &{1'b0, insn, sel};

endmodule
