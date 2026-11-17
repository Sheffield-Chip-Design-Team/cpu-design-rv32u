# RV32u ISA test: or: bitwise OR, including with a negative operand.
# expect: x7=0x0000000f x8=0xffffffff
    .section .text.init
    .global _start
_start:
    addi x5, x0, 12
    addi x6, x0, 3
    or   x7, x5, x6
    addi x9, x0, -16
    addi x10, x0, 15
    or   x8, x9, x10
halt:
    beq  x0, x0, halt
