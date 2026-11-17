# RV32u ISA test: lui: upper immediates, including bit 31.
# expect: x5=0x12345000 x6=0x80000000 x7=0xfffff000
    .section .text.init
    .global _start
_start:
    lui  x5, 0x12345
    lui  x6, 0x80000
    lui  x7, 0xfffff
halt:
    beq  x0, x0, halt
