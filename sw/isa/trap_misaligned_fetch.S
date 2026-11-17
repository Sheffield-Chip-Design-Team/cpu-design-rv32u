# RV32u ISA test: trap_misaligned_fetch: a jump to a PC with PC[1:0] != 0 traps at the target.
# expect: trap@0x0000000a
    .section .text.init
    .global _start
_start:
    addi x5, x0, 10
    jalr x0, x5, 0
halt:
    beq  x0, x0, halt
