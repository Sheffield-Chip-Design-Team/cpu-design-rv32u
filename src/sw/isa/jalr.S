# RV32u ISA test: jalr: indirect jump with bit 0 cleared; rd = rs1.
# expect: x1=0x0000000c x5=0x00000001 x6=0x00000000 x7=0x00000020
    .section .text.init
    .global _start
_start:
    addi x10, x0, 21
    addi x2, x0, 0
    jalr x1, x10, 0
    addi x6, x0, 1
    addi x6, x0, 1
target:
    addi x5, x0, 1
    addi x7, x0, 35
    jalr x7, x7, 1
    addi x6, x0, 2
    addi x0, x0, 0
halt:
    beq  x0, x0, halt
