// SPDX-License-Identifier: Apache-2.0
// RV32u control unit: the multi-cycle FSM (spec 05-control-fsm.md).
//
// YOURS TO DESIGN AND IMPLEMENT (design decisions D6, D7, D8): the states, what each
// does, their encoding and the control signals (types in rv32u_ctrl.svh). The tests
// check only the instructions the core retires, not its states or cycle counts.
//
// It also decides when an instruction retires (ctrl -> datapath -> the retire port)
// and enforces the trap rule (spec 06-retire-and-trap.md).

`default_nettype none

module rv32u_control (
    input  logic    clk,
    input  logic    rst_n,   // synchronous, active low
    input  rv32u_pkg::status_t status,
    output rv32u_pkg::ctrl_t   ctrl,
    output logic    trap     // high once the core has trapped (until reset)
);

  rv32u_pkg::state_e state, state_next;

  // TODO(D6): the state register (synchronous reset to your first state).
  always_ff @(posedge clk) begin
    if (!rst_n) state <= rv32u_pkg::S_FETCH;
    else        state <= state_next;
  end

  // TODO(D6/D7/D8): next-state logic and the control signals of every state.
  always_comb begin
    state_next = state;
    ctrl       = '0;
  end

  assign trap = 1'b0;

  wire _unused = &{1'b0, status};

endmodule
