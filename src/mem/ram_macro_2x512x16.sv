// SPDX-License-Identifier: Apache-2.0
// RV32u RAM, option macro_2x512x16 (decision D1): two IHP RM_IHPSG13_1P_512x16 macros
// side by side, the low and high halves of each 32-bit word: 512 x 32-bit = 2 KiB,
// 2 x (236.80 x 191.34 um). Synchronous read: rdata is valid the cycle after a read.

`default_nettype none

module rv32u_ram #(
    parameter int WORDS = 512
) (
    input  logic                     clk,
    input  logic                     en,
    input  logic                     we,
    input  logic [$clog2(WORDS)-1:0] addr,
    input  logic [31:0]              wdata,
    output logic [31:0]              rdata
);

  // keep: LibreLane places these instances by name (src/config.json MACROS).
  (* keep *)
  RM_IHPSG13_1P_512x16_c2_bm_bist u_lo (
      .A_CLK (clk), .A_MEN (en), .A_WEN (en && we), .A_REN (en && !we),
      .A_ADDR (9'(addr)), .A_DIN (wdata[15:0]), .A_DLY (1'b1), .A_DOUT (rdata[15:0]),
      .A_BM (16'hFFFF),
      .A_BIST_CLK (1'b0), .A_BIST_EN (1'b0), .A_BIST_MEN (1'b0), .A_BIST_WEN (1'b0),
      .A_BIST_REN (1'b0), .A_BIST_ADDR (9'd0), .A_BIST_DIN (16'd0), .A_BIST_BM (16'd0)
  );

  (* keep *)
  RM_IHPSG13_1P_512x16_c2_bm_bist u_hi (
      .A_CLK (clk), .A_MEN (en), .A_WEN (en && we), .A_REN (en && !we),
      .A_ADDR (9'(addr)), .A_DIN (wdata[31:16]), .A_DLY (1'b1), .A_DOUT (rdata[31:16]),
      .A_BM (16'hFFFF),
      .A_BIST_CLK (1'b0), .A_BIST_EN (1'b0), .A_BIST_MEN (1'b0), .A_BIST_WEN (1'b0),
      .A_BIST_REN (1'b0), .A_BIST_ADDR (9'd0), .A_BIST_DIN (16'd0), .A_BIST_BM (16'd0)
  );

endmodule
