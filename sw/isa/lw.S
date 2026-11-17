# RV32u ISA test: lw: loads with positive and negative offsets, from code and from stored data.
# expect: x6=0x0000002a x7=0x0000002a x8=0x20000293
    .section .text.init
    .global _start
_start:
    addi x5, x0, 0x200
    addi x10, x0, 42
    sw   x10, 4(x5)
    lw   x6, 4(x5)
    addi x9, x5, 8
    lw   x7, -4(x9)
    lw   x8, 0(x0)
halt:
    beq  x0, x0, halt
