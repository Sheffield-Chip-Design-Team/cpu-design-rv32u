// SPDX-License-Identifier: Apache-2.0
// RV32u I/O region (addr[31] = 1): YOURS TO DESIGN (decisions D3 memory map, D4 halt /
// done signalling, D5 pinout).
//
// It is a bus slave on the same valid/ready protocol as the RAM (spec 03-memory-bus.md).
// The starter is a do-nothing responder so the provided tests run: every access
// completes in one cycle, reads return 0, writes are ignored and no pin is driven.
// Replace it with the registers you specify in D3 (e.g. a GPIO output register that
// drives uo_out, a status register, a cycle counter) and record the map in DESIGN.md.

`default_nettype none

module rv32u_io (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        io_valid,
    output logic        io_ready,
    input  logic [31:0] io_addr,
    input  logic [31:0] io_wdata,
    input  logic [3:0]  io_wstrb,
    output logic [31:0] io_rdata,

    input  logic        trap,      // from the core, for D4

    // pins this block may own (D5): the Tiny Tapeout dedicated outputs and the
    // bidirectional pins not used by the loader
    output logic [7:0]  gpio_out,
    input  logic [7:0]  gpio_in,
    output logic [7:0]  gpio_oe
);

  // TODO(D3): your I/O registers. TODO(D4): how software (and you, on the board) can
  // tell that a program has finished. TODO(D5): which pins they use.
  assign io_ready = io_valid;
  assign io_rdata = 32'd0;
  assign gpio_out = 8'd0;
  assign gpio_oe  = 8'd0;

  wire _unused = &{1'b0, clk, rst_n, io_addr, io_wdata, io_wstrb, trap, gpio_in};

endmodule
