// SPDX-License-Identifier: Apache-2.0
// RV32u register file: 32 x 32-bit, two combinational read ports, one synchronous
// write port. x0 reads as zero and ignores writes (spec 02-isa.md, "Architectural state").
//
// YOURS TO IMPLEMENT. Write a unit test for it (spec 09-verification.md).

`default_nettype none

module rv32u_regfile (
    input  logic        clk,
    // read ports (combinational)
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    // write port (on the rising edge of clk when we is high)
    input  logic        we,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data
);

  // TODO(spec 02): the storage, the two read ports and the write port.
  // Remember: x0 is hardwired to zero, whatever is written to it.
  assign rs1_data = 32'd0;
  assign rs2_data = 32'd0;

  wire _unused = &{1'b0, clk, rs1_addr, rs2_addr, we, rd_addr, rd_data};

endmodule
