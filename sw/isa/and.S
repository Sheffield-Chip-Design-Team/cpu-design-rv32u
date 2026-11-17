# RV32u ISA test: and: bitwise AND with a negative operand.
# expect: x7=0x0000000c x8=0x00000000
    .section .text.init
    .global _start
_start:
    addi x5, x0, 12
    addi x6, x0, -3
    and  x7, x5, x6
    addi x9, x0, 3
    and  x8, x5, x9
halt:
    beq  x0, x0, halt
