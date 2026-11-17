// SPDX-License-Identifier: Apache-2.0
// RV32u program loader: YOURS TO DESIGN (decision D2).
//
// On silicon, the RAM is empty at power-up. The loader is how a compiled program gets
// into it: it holds the core in reset (core_rst_n low), writes words through the
// memory subsystem's loader port (ld_we / ld_addr / ld_wdata: one word per cycle, word
// aligned), then releases the core. Choose the interface (an SPI slave, a UART, a
// parallel strobe on uio, ...), its pins (D5) and its protocol, and record them in
// DESIGN.md.
//
// The starter never loads anything and lets the core run straight out of reset;
// simulation preloads the RAM through a testbench backdoor instead (verif/).

`default_nettype none

module rv32u_loader (
    input  logic        clk,
    input  logic        rst_n,      // the chip's reset

    output logic        core_rst_n, // the core's reset (hold it low while loading)

    output logic        ld_we,
    output logic [31:0] ld_addr,
    output logic [31:0] ld_wdata,

    // pins this block may own (D5)
    input  logic [7:0]  ui_in,
    input  logic [7:0]  uio_in,
    output logic [7:0]  uio_out,
    output logic [7:0]  uio_oe
);

  // TODO(D2): your loader.
  assign core_rst_n = rst_n;
  assign ld_we      = 1'b0;
  assign ld_addr    = 32'd0;
  assign ld_wdata   = 32'd0;
  assign uio_out    = 8'd0;
  assign uio_oe     = 8'd0;

  wire _unused = &{1'b0, clk, ui_in, uio_in};

endmodule
