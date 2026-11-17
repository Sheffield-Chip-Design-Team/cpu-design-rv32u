# RV32u ISA test: trap_illegal: an instruction outside RV32u (sll) traps.
# expect: trap@0x00000008
    .section .text.init
    .global _start
_start:
    addi x5, x0, 1
    addi x6, x0, 2
    .word 0x006292b3
halt:
    beq  x0, x0, halt
