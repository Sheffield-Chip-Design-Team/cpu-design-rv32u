// SPDX-License-Identifier: Apache-2.0
// RV32u datapath: PC, OldPC, IR, MDR, A, B, ALUOut, the register file, the ALU, the
// immediate generator, the operand multiplexers, the memory bus and the retire port
// (spec 04-microarchitecture.md, 03-memory-bus.md, 06-retire-and-trap.md).
//
// YOURS TO IMPLEMENT. Everything it does is commanded by `ctrl` (your D7 signals); it
// reports back through `status`.

`default_nettype none

module rv32u_datapath (
    input  logic        clk,
    input  logic        rst_n,
    input  rv32u_pkg::ctrl_t       ctrl,
    output rv32u_pkg::status_t     status,

    // memory bus master (spec 03-memory-bus.md)
    output logic        mem_valid,
    input  logic        mem_ready,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    input  logic [31:0] mem_rdata,

    // retire port (spec 06-retire-and-trap.md): one rvfi_valid pulse per instruction
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

  // ---- the sub-blocks (connect them) ------------------------------------------------
  logic [31:0] rs1_data, rs2_data, imm, alu_y;
  logic        alu_eq, alu_lt;

  // TODO(spec 04): drive these from your registers and ctrl.
  logic [4:0]  rf_rs1, rf_rs2, rf_rd;
  logic        rf_we;
  logic [31:0] rf_wdata, alu_a, alu_b;
  assign rf_rs1   = 5'd0;
  assign rf_rs2   = 5'd0;
  assign rf_rd    = 5'd0;
  assign rf_we    = 1'b0;
  assign rf_wdata = 32'd0;
  assign alu_a    = 32'd0;
  assign alu_b    = 32'd0;

  rv32u_regfile u_regfile (
      .clk      (clk),
      .rs1_addr (rf_rs1),
      .rs2_addr (rf_rs2),
      .rs1_data (rs1_data),
      .rs2_data (rs2_data),
      .we       (rf_we),
      .rd_addr  (rf_rd),
      .rd_data  (rf_wdata)
  );

  rv32u_alu u_alu (
      .op (ctrl.alu_op),
      .a  (alu_a),
      .b  (alu_b),
      .y  (alu_y),
      .eq (alu_eq),
      .lt (alu_lt)
  );

  rv32u_immgen u_immgen (
      .insn (32'd0),  // TODO: the IR
      .sel  (ctrl.imm_sel),
      .imm  (imm)
  );

  // TODO(spec 04): the non-architectural registers PC, OldPC, IR, MDR, A, B, ALUOut,
  // their write enables and input multiplexers (D8), all under ctrl.

  // TODO(spec 03): the memory request.
  assign mem_valid = 1'b0;
  assign mem_addr  = 32'd0;
  assign mem_wdata = 32'd0;
  assign mem_wstrb = 4'b0000;

  // TODO(spec 06): the retire port.
  assign rvfi_valid     = 1'b0;
  assign rvfi_trap      = 1'b0;
  assign rvfi_pc        = 32'd0;
  assign rvfi_pc_next   = 32'd0;
  assign rvfi_insn      = 32'd0;
  assign rvfi_rd_addr   = 5'd0;
  assign rvfi_rd_wdata  = 32'd0;
  assign rvfi_mem_addr  = 32'd0;
  assign rvfi_mem_wstrb = 4'b0000;
  assign rvfi_mem_wdata = 32'd0;
  assign rvfi_mem_rdata = 32'd0;

  // TODO: report the datapath's state to the control unit.
  assign status.insn            = 32'd0;
  assign status.mem_ready       = mem_ready;
  assign status.alu_eq          = alu_eq;
  assign status.alu_lt          = alu_lt;
  assign status.pc_misaligned   = 1'b0;
  assign status.addr_misaligned = 1'b0;

  wire _unused = &{1'b0, clk, rst_n, ctrl, mem_rdata, rs1_data, rs2_data, imm, alu_y};

endmodule
