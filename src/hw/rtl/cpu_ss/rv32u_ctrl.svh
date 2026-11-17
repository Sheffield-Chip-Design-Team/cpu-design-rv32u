// SPDX-License-Identifier: Apache-2.0
// RV32u control interface: YOURS TO DESIGN (design decisions D6, D7, D8).
//
// This file is `include'd inside package rv32u_pkg (src/rv32u_pkg.sv), so everything
// here is rv32u_pkg::<name>. (Yosys, Tiny Tapeout's synthesis tool, supports only one
// package without imports, so the control types live in it.)
//
// rv32u_control drives the datapath through one packed struct, ctrl_t, and reads the
// datapath's state through another, status_t. Both are defined here so the two modules
// always agree. Record the final versions in DESIGN.md (D6 state encoding, D7 control
// signal table, D8 ALU operand selection).
//
// What is fixed (spec 05-control-fsm.md): only what the core retires, the bus protocol
// and the trap rule. Your states, what each does, the cycles every instruction takes,
// the encoding, the control signals and the ALU operand multiplexers are all yours.

  // ---- D6: state encoding -------------------------------------------------------------
  // TODO(D6): list your states, and pick their width and encoding (binary, one-hot,
  // Gray ...): justify it in DESIGN.md. S_FETCH is only a placeholder.
  typedef enum logic [2:0] {
    S_FETCH = 3'd0
  } state_e;

  // ---- D7: control signals (control -> datapath) --------------------------------------
  // TODO(D7): one field per control signal your datapath needs: register write enables
  // (PC, OldPC, IR, A/B, ALUOut, MDR, register file), the memory request, the
  // write-back source, the retire pulse ... Keep it minimal and document every field.
  typedef struct packed {
    alu_op_e  alu_op;   // operation for rv32u_alu
    imm_sel_e imm_sel;  // immediate format for rv32u_immgen
    // TODO(D8): ALU operand A / operand B selects
    // TODO(D7): the rest
    logic     placeholder;  // delete once you have real fields
  } ctrl_t;

  // ---- status (datapath -> control) ---------------------------------------------------
  // Provided, extend if your control needs more.
  typedef struct packed {
    logic [31:0] insn;           // the Instruction Register (IR)
    logic        mem_ready;      // the memory bus handshake
    logic        alu_eq;         // A == B  (BEQ)
    logic        alu_lt;         // A <  B, signed (BLT, SLT)
    logic        pc_misaligned;  // PC[1:0]     != 0  (trap rule)
    logic        addr_misaligned;// ALUOut[1:0] != 0  (trap rule, LW/SW)
  } status_t;

