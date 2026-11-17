// RV32u RAM size: YOURS TO SET (design decision D1, spec 07-memory-subsystem.md).
//
// The number of 32-bit words in your RAM. It must match what rv32u_ram.sv builds:
//   one 512x32 macro, or two 512x16 macros side by side   -> 512 (2 KiB)
//   a flip-flop array                                      -> what you can afford: 16-512
// The RTL (rv32u_mem_ss), the software build (src/sw: the stack starts at the top of the
// RAM) and the tests all read it. After changing it: make -C src/sw clean.
`ifndef RV32U_MEM_CONFIG_SVH
`define RV32U_MEM_CONFIG_SVH
`define RV32U_RAM_WORDS 512  // TODO(D1)
`endif
