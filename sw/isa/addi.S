# RV32u ISA test: addi: positive, negative and extreme 12-bit immediates; a chain through one register.
# expect: x5=0x00000005 x6=0xfffffffd x7=0x000007ff x8=0xfffff800 x9=0x00000002
    .section .text.init
    .global _start
_start:
    addi x5, x0, 5
    addi x6, x0, -3
    addi x7, x0, 2047
    addi x8, x0, -2048
    addi x9, x5, -3
halt:
    beq  x0, x0, halt
