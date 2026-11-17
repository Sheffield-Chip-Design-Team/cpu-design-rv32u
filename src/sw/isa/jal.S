# RV32u ISA test: jal: forward and backward jumps; the link register.
# expect: x1=0x00000004 x5=0x00000001 x6=0x00000000 x7=0x0000001c x8=0x00000002
    .section .text.init
    .global _start
_start:
    jal  x1, forward
    addi x6, x0, 1
forward:
    addi x5, x0, 1
    jal  x0, over
back:
    addi x8, x0, 2
    jal  x0, done
over:
    jal  x7, back
done:
halt:
    beq  x0, x0, halt
