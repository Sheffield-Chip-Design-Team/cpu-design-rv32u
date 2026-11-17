# RV32u ISA test: slt: signed less-than: negative < positive, equal, and the reverse.
# expect: x7=0x00000001 x8=0x00000000 x9=0x00000000 x10=0x00000001
    .section .text.init
    .global _start
_start:
    addi x5, x0, -1
    addi x6, x0, 1
    slt  x7, x5, x6
    slt  x8, x6, x5
    slt  x9, x6, x6
    lui  x11, 0x80000
    slt  x10, x11, x5
halt:
    beq  x0, x0, halt
