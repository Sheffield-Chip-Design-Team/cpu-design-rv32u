# RV32u ISA test: sub: difference, negative result and wrap-around.
# expect: x7=0x00000008 x8=0xfffffff8 x9=0x80000000
    .section .text.init
    .global _start
_start:
    addi x5, x0, 5
    addi x6, x0, -3
    sub  x7, x5, x6
    sub  x8, x6, x5
    lui  x10, 0x80000
    addi x10, x10, -1
    addi x11, x0, -1
    sub  x9, x10, x11
halt:
    beq  x0, x0, halt
