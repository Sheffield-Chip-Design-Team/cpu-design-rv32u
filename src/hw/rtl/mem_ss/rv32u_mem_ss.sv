// SPDX-License-Identifier: Apache-2.0
// RV32u memory subsystem (spec 07-memory-subsystem.md). This file is provided; the RAM
// it instantiates, rv32u_ram (rv32u_ram.sv), is yours (decision D1).
//
// A valid/ready bus slave (spec 03-memory-bus.md) that decodes the address:
//   [0, RAM_BYTES)        on-chip RAM: one wait state (mem_ready one cycle after the
//                         request is accepted), because every RAM option reads
//                         synchronously.
//   addr[31] = 1          the I/O region: forwarded to the io_* port (decision D3).
//   anything else         unmapped: completes with one wait state, reads return 0,
//                         writes are ignored.
// The loader port (decision D2) writes RAM words directly; use it only while the core
// is held in reset.

`default_nettype none
`include "mem_config.svh"

module rv32u_mem_ss #(
    parameter int RAM_WORDS = `RV32U_RAM_WORDS
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

  localparam int AW = $clog2(RAM_WORDS);
  localparam logic [31:0] RAM_BYTES = RAM_WORDS * 4;

  logic is_io, is_ram;
  assign is_io  = mem_addr[31];
  assign is_ram = !is_io && (mem_addr < RAM_BYTES);

  // one transaction in flight: `pending` is high in the cycle the reply is returned
  logic pending, pending_ram;
  logic accept;
  assign accept = mem_valid && !is_io && !pending;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pending     <= 1'b0;
      pending_ram <= 1'b0;
    end else begin
      pending     <= accept;
      pending_ram <= accept && is_ram;
    end
  end

  // ---- the RAM (yours: rv32u_ram.sv, decision D1) --------------------------------------
  logic          ram_en, ram_we;
  logic [AW-1:0] ram_addr;
  logic [31:0]   ram_wdata, ram_rdata;

  // the loader has priority (it only runs while the core is held in reset)
  assign ram_en    = ld_we || (accept && is_ram);
  assign ram_we    = ld_we || (mem_wstrb == 4'b1111);
  assign ram_addr  = ld_we ? ld_addr[AW+1:2] : mem_addr[AW+1:2];
  assign ram_wdata = ld_we ? ld_wdata : mem_wdata;

  rv32u_ram #(.WORDS(RAM_WORDS)) u_ram (
      .clk   (clk),
      .en    (ram_en),
      .we    (ram_we),
      .addr  (ram_addr),
      .wdata (ram_wdata),
      .rdata (ram_rdata)
  );

  // ---- the I/O region -------------------------------------------------------------------
  assign io_valid = mem_valid && is_io;
  assign io_addr  = mem_addr;
  assign io_wdata = mem_wdata;
  assign io_wstrb = mem_wstrb;

  // ---- reply to the core --------------------------------------------------------------
  assign mem_ready = is_io ? io_ready : pending;
  assign mem_rdata = is_io ? io_rdata : (pending_ram ? ram_rdata : 32'd0);

  wire _unused = &{1'b0, ld_addr[31:AW+2], ld_addr[1:0]};

endmodule
