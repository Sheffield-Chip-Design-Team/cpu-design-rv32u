// SPDX-License-Identifier: Apache-2.0
// RV32u system: the CPU, memory and I/O subsystems and the loader (provided wiring).
// The retire port is brought out for verification only; the Tiny Tapeout top leaves
// it unconnected.

`default_nettype none

module rv32u_soc (
    input  logic        clk,
    input  logic        rst_n,

    // Tiny Tapeout pins, shared between the loader and the I/O block (D5)
    input  logic [7:0]  ui_in,
    output logic [7:0]  uo_out,
    input  logic [7:0]  uio_in,
    output logic [7:0]  uio_out,
    output logic [7:0]  uio_oe,

    output logic        trap,

    // retire port (verification only)
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

  logic        core_rst_n;
  logic        mem_valid, mem_ready;
  logic [31:0] mem_addr, mem_wdata, mem_rdata;
  logic [3:0]  mem_wstrb;
  logic        io_valid, io_ready;
  logic [31:0] io_addr, io_wdata, io_rdata;
  logic [3:0]  io_wstrb;
  logic        ld_we, mem_ld_we, cpu_rst_n;
  logic [31:0] ld_addr, ld_wdata, mem_ld_addr, mem_ld_wdata;
  logic [7:0]  ld_uio_out, ld_uio_oe, gpio_out, gpio_oe;

  rv32u_loader u_loader (
      .clk        (clk),
      .rst_n      (rst_n),
      .core_rst_n (core_rst_n),
      .ld_we      (ld_we),
      .ld_addr    (ld_addr),
      .ld_wdata   (ld_wdata),
      .ui_in      (ui_in),
      .uio_in     (uio_in),
      .uio_out    (ld_uio_out),
      .uio_oe     (ld_uio_oe)
  );

  rv32u_cpu_ss u_cpu (
      .clk            (clk),
      .rst_n          (cpu_rst_n),
      .mem_valid      (mem_valid),
      .mem_ready      (mem_ready),
      .mem_addr       (mem_addr),
      .mem_wdata      (mem_wdata),
      .mem_wstrb      (mem_wstrb),
      .mem_rdata      (mem_rdata),
      .trap           (trap),
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

  rv32u_mem_ss u_mem (
      .clk       (clk),
      .rst_n     (rst_n),
      .mem_valid (mem_valid),
      .mem_ready (mem_ready),
      .mem_addr  (mem_addr),
      .mem_wdata (mem_wdata),
      .mem_wstrb (mem_wstrb),
      .mem_rdata (mem_rdata),
      .io_valid  (io_valid),
      .io_ready  (io_ready),
      .io_addr   (io_addr),
      .io_wdata  (io_wdata),
      .io_wstrb  (io_wstrb),
      .io_rdata  (io_rdata),
      .ld_we     (mem_ld_we),
      .ld_addr   (mem_ld_addr),
      .ld_wdata  (mem_ld_wdata)
  );

`ifdef SIM
  // Test load port (simulation only). The provided tests load each program through the
  // memory subsystem's loader port, one word per cycle, while tb_load holds the CPU in
  // reset: the same path your loader (D2) uses, so it works whatever your RAM is (D1).
  // The tests drive these variables directly; nothing in the design does.
  logic        tb_load     = 1'b0;
  logic        tb_ld_we    = 1'b0;
  logic [31:0] tb_ld_addr  = 32'd0;
  logic [31:0] tb_ld_wdata = 32'd0;
  assign mem_ld_we    = tb_load ? tb_ld_we    : ld_we;
  assign mem_ld_addr  = tb_load ? tb_ld_addr  : ld_addr;
  assign mem_ld_wdata = tb_load ? tb_ld_wdata : ld_wdata;
  assign cpu_rst_n    = core_rst_n && !tb_load;
`else
  assign mem_ld_we    = ld_we;
  assign mem_ld_addr  = ld_addr;
  assign mem_ld_wdata = ld_wdata;
  assign cpu_rst_n    = core_rst_n;
`endif

  rv32u_io u_io (
      .clk      (clk),
      .rst_n    (rst_n),
      .io_valid (io_valid),
      .io_ready (io_ready),
      .io_addr  (io_addr),
      .io_wdata (io_wdata),
      .io_wstrb (io_wstrb),
      .io_rdata (io_rdata),
      .trap     (trap),
      .gpio_out (gpio_out),
      .gpio_in  (uio_in),
      .gpio_oe  (gpio_oe)
  );

  // D5: the starter gives uo_out to the I/O block and uio to whichever block enables a
  // pin (the loader wins). Change this to match your pinout.
  assign uo_out  = gpio_out;
  assign uio_out = (ld_uio_oe & ld_uio_out) | (~ld_uio_oe & gpio_oe & gpio_out);
  assign uio_oe  = ld_uio_oe | gpio_oe;

`ifdef SIM
`ifndef VERILATOR
  // Waveforms for the provided tests on Icarus: make isa SIM=icarus WAVES=1
  initial begin
    if ($test$plusargs("waves")) begin
      $dumpfile("rv32u.fst");
      $dumpvars(0, rv32u_soc);
    end
  end
`endif
`endif

endmodule
