# RV32u ISA test: add: sum, wrap-around and rd = rs1 = rs2.
# expect: x7=0x00000002 x8=0x00000000 x9=0x00000004
    .section .text.init
    .global _start
_start:
    addi x5, x0, 5
    addi x6, x0, -3
    add  x7, x5, x6
    addi x10, x0, -1
    addi x11, x0, 1
    add  x8, x10, x11
    addi x9, x0, 2
    add  x9, x9, x9
halt:
    beq  x0, x0, halt
