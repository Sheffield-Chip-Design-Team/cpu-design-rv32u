// SPDX-License-Identifier: Apache-2.0
// RV32u core: the control unit and the datapath (provided wiring; spec 04, 05).
// The memory bus and the retire port are the core's whole interface.

`default_nettype none

module rv32u_core (
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

  rv32u_pkg::ctrl_t   ctrl;
  rv32u_pkg::status_t status;

  rv32u_control u_control (
      .clk    (clk),
      .rst_n  (rst_n),
      .status (status),
      .ctrl   (ctrl),
      .trap   (trap)
  );

  rv32u_datapath u_datapath (
      .clk            (clk),
      .rst_n          (rst_n),
      .ctrl           (ctrl),
      .status         (status),
      .mem_valid      (mem_valid),
      .mem_ready      (mem_ready),
      .mem_addr       (mem_addr),
      .mem_wdata      (mem_wdata),
      .mem_wstrb      (mem_wstrb),
      .mem_rdata      (mem_rdata),
      .rvfi_valid     (rvfi_valid),
      .rvfi_trap      (rvfi_trap),
      .rvfi_pc        (rvfi_pc),
      .rvfi_pc_next   (rvfi_pc_next),
      .rvfi_insn      (rvfi_insn),
      .rvfi_rd_addr   (rvfi_rd_addr),
      .rvfi_rd_wdata  (rvfi_rd_wdata),
      .rvfi_mem_addr  (rvfi_mem_addr),
      .rvfi_mem_wstrb (rvfi_mem_wstrb),
      .rvfi_mem_wdata (rvfi_mem_wdata),
      .rvfi_mem_rdata (rvfi_mem_rdata)
  );

endmodule
