# RV32u ISA test: beq: taken and not-taken, forward and backward.
# expect: x5=0x00000001 x6=0x00000000 x7=0x00000003
    .section .text.init
    .global _start
_start:
    addi x10, x0, 4
    addi x11, x0, 4
    beq  x10, x11, taken
    addi x6, x0, 1
taken:
    addi x5, x0, 1
    beq  x10, x0, never
    addi x7, x0, 0
loop:
    addi x7, x7, 1
    addi x12, x0, 3
    beq  x7, x12, out
    beq  x0, x0, loop
never:
    addi x6, x0, 2
out:
halt:
    beq  x0, x0, halt
