// SPDX-License-Identifier: Apache-2.0
// RV32u CPU subsystem: YOURS TO DESIGN AND IMPLEMENT (spec 04, 05, 06).
//
// The ports are fixed: rv32u_soc and the tests connect to them. Everything inside is
// yours, including how you split it into modules (decision D7). Spec chapter 4 suggests
// a split (register file, ALU, immediate generator, control FSM, datapath), each in its
// own file in this directory; a single file works too, but is hard to test and to read.
// Add every file you create to rv32u_cpu_ss.core and to info.yaml source_files.

`default_nettype none

module rv32u_cpu_ss (
    input  logic        clk,
    input  logic        rst_n,   // synchronous, active low

    // memory bus master (spec 03-memory-bus.md)
    output logic        mem_valid,
    input  logic        mem_ready,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    input  logic [31:0] mem_rdata,

    output logic        trap,    // the core has trapped and stopped (spec 06)

    // retire port: debug and verification only, not on the chip's pins (spec 06)
    output logic        rvfi_valid,
    output logic        rvfi_trap,
    output logic [31:0] rvfi_pc,
    output logic [31:0] rvfi_pc_next,
    output logic [31:0] rvfi_insn,
    output logic [4:0]  rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    output logic [31:0] rvfi_mem_addr,
    output logic [3:0]  rvfi_mem_wstrb,
    output logic [31:0] rvfi_mem_wdata,
    output logic [31:0] rvfi_mem_rdata
);

  // TODO: your CPU. The starter drives every output to 0, so no instruction retires.
  assign mem_valid      = 1'b0;
  assign mem_addr       = 32'd0;
  assign mem_wdata      = 32'd0;
  assign mem_wstrb      = 4'd0;
  assign trap           = 1'b0;
  assign rvfi_valid     = 1'b0;
  assign rvfi_trap      = 1'b0;
  assign rvfi_pc        = 32'd0;
  assign rvfi_pc_next   = 32'd0;
  assign rvfi_insn      = 32'd0;
  assign rvfi_rd_addr   = 5'd0;
  assign rvfi_rd_wdata  = 32'd0;
  assign rvfi_mem_addr  = 32'd0;
  assign rvfi_mem_wstrb = 4'd0;
  assign rvfi_mem_wdata = 32'd0;
  assign rvfi_mem_rdata = 32'd0;

  wire _unused = &{1'b0, clk, rst_n, mem_ready, mem_rdata};

endmodule
