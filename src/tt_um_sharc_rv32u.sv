// SPDX-License-Identifier: Apache-2.0
// Tiny Tapeout top level for the RV32u mini-project (IHP SG13CMOS5L; tiles: info.yaml, set by
// scripts/select-memory.py with the memory option, decision D1).
// The pin functions are decided by you (D5) and documented in info.yaml and
// docs/info.md.

`default_nettype none

module tt_um_sharc_rv32u (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // The retire port is for verification only: nothing on the chip uses it.
  logic        trap, rvfi_valid, rvfi_trap;
  logic [31:0] rvfi_pc, rvfi_pc_next, rvfi_insn, rvfi_rd_wdata, rvfi_mem_addr;
  logic [31:0] rvfi_mem_wdata, rvfi_mem_rdata;
  logic [4:0]  rvfi_rd_addr;
  logic [3:0]  rvfi_mem_wstrb;

  rv32u_soc u_soc (
      .clk            (clk),
      .rst_n          (rst_n),
      .ui_in          (ui_in),
      .uo_out         (uo_out),
      .uio_in         (uio_in),
      .uio_out        (uio_out),
      .uio_oe         (uio_oe),
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

  wire _unused = &{1'b0, ena, trap, rvfi_valid, rvfi_trap, rvfi_pc, rvfi_pc_next, rvfi_insn,
                    rvfi_rd_addr, rvfi_rd_wdata, rvfi_mem_addr, rvfi_mem_wstrb, rvfi_mem_wdata,
                    rvfi_mem_rdata};

endmodule
