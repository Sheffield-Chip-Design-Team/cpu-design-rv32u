# RV32u ISA test: x0: writes to x0 are ignored; x0 always reads 0.
# expect: x5=0x00000000 x6=0x00000000 x7=0x00000007
    .section .text.init
    .global _start
_start:
    addi x0, x0, 5
    add  x5, x0, x0
    lui  x0, 0x12345
    or   x6, x0, x0
    addi x7, x0, 7
    jal  x0, next
next:
halt:
    beq  x0, x0, halt
