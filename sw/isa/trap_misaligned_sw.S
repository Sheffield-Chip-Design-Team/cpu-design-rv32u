# RV32u ISA test: trap_misaligned_sw: SW to an address with addr[1:0] != 0 traps.
# expect: trap@0x00000004
    .section .text.init
    .global _start
_start:
    addi x5, x0, 0x201
    sw   x0, 0(x5)
halt:
    beq  x0, x0, halt
