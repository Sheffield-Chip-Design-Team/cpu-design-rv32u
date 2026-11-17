// SPDX-License-Identifier: Apache-2.0
// RV32u RAM, option flops (decision D1): a flip-flop array with the same synchronous
// read as the macros (rdata valid the cycle after a read). No macro, no special power
// grid, but about 7.25 GE per bit: 2 KiB would be ~120k GE (~28 tiles), so this option
// uses fewer words (RV32U_RAM_WORDS in mem_config.svh; see D1 for the budget).

`default_nettype none

module rv32u_ram #(
    parameter int WORDS = 128
) (
    input  logic                     clk,
    input  logic                     en,
    input  logic                     we,
    input  logic [$clog2(WORDS)-1:0] addr,
    input  logic [31:0]              wdata,
    output logic [31:0]              rdata
);

  logic [31:0] mem [WORDS];

  always_ff @(posedge clk) begin
    if (en) begin
      if (we) mem[addr] <= wdata;
      else    rdata     <= mem[addr];
    end
  end

endmodule
