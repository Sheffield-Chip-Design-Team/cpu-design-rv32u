# RV32u ISA test: sw: stores at positive and negative offsets; read back.
# expect: x7=0x00000063 x8=0xfffffffb mem[0x204]=0x00000063 mem[0x1fc]=0xfffffffb
    .section .text.init
    .global _start
_start:
    addi x5, x0, 0x200
    addi x10, x0, 99
    addi x11, x0, -5
    sw   x10, 4(x5)
    sw   x11, -4(x5)
    lw   x7, 4(x5)
    lw   x8, -4(x5)
halt:
    beq  x0, x0, halt
