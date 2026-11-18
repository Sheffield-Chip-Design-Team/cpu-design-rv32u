// SPDX-License-Identifier: Apache-2.0
// RV32u memory subsystem: YOURS TO DESIGN AND IMPLEMENT (decision D1, spec 07).
//
// The ports and the RAM_WORDS parameter are fixed: rv32u_soc, your loader, the tests and
// the software build all use them. Everything inside is yours: a bus slave for the CPU
// (spec 03), the address decode (RAM, unmapped, the I/O region), the loader port, and
// the RAM itself, built from flip-flops or from your IHP SRAM macro wrappers
// (src/hw/pd/wrappers/). Put sub-modules in their own files in this directory, and list
// every file in rv32u_mem_ss.core and info.yaml source_files.
//
// The starter never answers a request, so the CPU waits forever on its first fetch.

`default_nettype none

module rv32u_mem_ss #(
  // The RAM size in 32-bit words (decision D1): 512 for the SRAM macros, 16-512 for
  // flip-flops. The software build and the tests read this value too.
  parameter int RAM_WORDS = 512
) (
    input  logic        clk,
    input  logic        rst_n,

    // from the core
    input  logic        mem_valid,
    output logic        mem_ready,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic [3:0]  mem_wstrb,
    output logic [31:0] mem_rdata,

    // the I/O region (to rv32u_io)
    output logic        io_valid,
    input  logic        io_ready,
    output logic [31:0] io_addr,
    output logic [31:0] io_wdata,
    output logic [3:0]  io_wstrb,
    input  logic [31:0] io_rdata,

    // loader port (from rv32u_loader): one word per cycle while ld_we is high
    input  logic        ld_we,
    input  logic [31:0] ld_addr,   // byte address, word aligned
    input  logic [31:0] ld_wdata
);

  // TODO(D1): your memory subsystem.
  assign mem_ready = 1'b0;
  assign mem_rdata = 32'd0;
  assign io_valid  = 1'b0;
  assign io_addr   = 32'd0;
  assign io_wdata  = 32'd0;
  assign io_wstrb  = 4'd0;

  wire _unused = &{1'b0, clk, rst_n, mem_valid, mem_addr, mem_wdata, mem_wstrb,
                   io_ready, io_rdata, ld_we, ld_addr, ld_wdata};

endmodule
