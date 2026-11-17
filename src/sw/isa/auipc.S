# RV32u ISA test: auipc: PC-relative upper immediates at two addresses.
# expect: x5=0x00001000 x6=0x00000004 x7=0xfffff008
    .section .text.init
    .global _start
_start:
    auipc x5, 0x1
    auipc x6, 0x0
    auipc x7, 0xfffff
halt:
    beq  x0, x0, halt
