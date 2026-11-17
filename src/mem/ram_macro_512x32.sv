// SPDX-License-Identifier: Apache-2.0
// RV32u RAM, option macro_512x32 (decision D1): one IHP RM_IHPSG13_1P_512x32 macro,
// 512 x 32-bit = 2 KiB, 416.64 x 191.34 um. Synchronous read: rdata is valid the cycle
// after a read (en=1, we=0).

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

  // keep: LibreLane places this instance by name (src/config.json MACROS), so synthesis
  // must not remove it even while nothing on the pins depends on the RAM yet.
  (* keep *)
  RM_IHPSG13_1P_512x32_c2_bm_bist u_macro (
      .A_CLK       (clk),
      .A_MEN       (en),
      .A_WEN       (en && we),
      .A_REN       (en && !we),
      .A_ADDR      (9'(addr)),
      .A_DIN       (wdata),
      .A_DLY       (1'b1),          // must be tied high (datasheet)
      .A_DOUT      (rdata),
      .A_BM        (32'hFFFF_FFFF), // word writes only
      .A_BIST_CLK  (1'b0),
      .A_BIST_EN   (1'b0),
      .A_BIST_MEN  (1'b0),
      .A_BIST_WEN  (1'b0),
      .A_BIST_REN  (1'b0),
      .A_BIST_ADDR (9'd0),
      .A_BIST_DIN  (32'd0),
      .A_BIST_BM   (32'd0)
  );

endmodule
