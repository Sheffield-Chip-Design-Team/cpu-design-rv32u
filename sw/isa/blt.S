# RV32u ISA test: blt: signed branches: negative < positive taken, the reverse not taken; a countdown loop.
# expect: x5=0x00000001 x6=0x00000000 x7=0x00000005
    .section .text.init
    .global _start
_start:
    addi x10, x0, -1
    addi x11, x0, 1
    blt  x10, x11, taken
    addi x6, x0, 1
taken:
    addi x5, x0, 1
    blt  x11, x10, never
    addi x7, x0, 0
loop:
    addi x7, x7, 1
    addi x12, x0, 5
    blt  x7, x12, loop
    jal  x0, out
never:
    addi x6, x0, 2
out:
halt:
    beq  x0, x0, halt
