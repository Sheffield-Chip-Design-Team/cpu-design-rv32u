// SPDX-License-Identifier: Apache-2.0
// RV32u RAM: YOURS TO DESIGN AND IMPLEMENT (design decision D1, spec 07-memory-subsystem.md).
//
// rv32u_mem_ss instantiates this module as u_ram. Build it from ONE of:
//   - IHP SRAM macros: write a wrapper for each macro type you use in
//     src/hw/pd/wrappers/ (it instantiates RM_IHPSG13_1P_512x32_c2_bm_bist or
//     RM_IHPSG13_1P_512x16_c2_bm_bist and ties off its BIST and test pins), then
//     instantiate your wrapper(s) here.
//   - flip-flops: write the storage array here.
// Then set RV32U_RAM_WORDS (mem_config.svh) and, for macros, src/config.json and
// info.yaml (spec chapter 7 has the checklist; make mem-check checks them).
//
// The contract, whatever is inside: on a rising edge with en high, write wdata to word
// addr if we is high, otherwise read word addr; rdata holds the word read from the
// cycle after the read until the next read (a synchronous read, like the macros).

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

  // TODO(D1): your RAM.
  assign rdata = 32'd0;

  wire _unused = &{1'b0, clk, en, we, addr, wdata};

endmodule
