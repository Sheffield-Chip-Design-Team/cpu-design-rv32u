# RV32u C runtime start-up (spec 08-software-flow.md). Uses only RV32u instructions.
# Clears every register (their reset value is unspecified, and GCC saves callee-saved
# registers before ever writing them), sets the stack pointer to the top of RAM, clears
# .bss, calls main(), then halts in a self-loop (the provided tests stop when an
# instruction jumps to itself).
    .section .text.init
    .global _start
_start:
    addi  x1, x0, 0
    addi  x2, x0, 0
    addi  x3, x0, 0
    addi  x4, x0, 0
    addi  x5, x0, 0
    addi  x6, x0, 0
    addi  x7, x0, 0
    addi  x8, x0, 0
    addi  x9, x0, 0
    addi  x10, x0, 0
    addi  x11, x0, 0
    addi  x12, x0, 0
    addi  x13, x0, 0
    addi  x14, x0, 0
    addi  x15, x0, 0
    addi  x16, x0, 0
    addi  x17, x0, 0
    addi  x18, x0, 0
    addi  x19, x0, 0
    addi  x20, x0, 0
    addi  x21, x0, 0
    addi  x22, x0, 0
    addi  x23, x0, 0
    addi  x24, x0, 0
    addi  x25, x0, 0
    addi  x26, x0, 0
    addi  x27, x0, 0
    addi  x28, x0, 0
    addi  x29, x0, 0
    addi  x30, x0, 0
    addi  x31, x0, 0
    lui   sp, %hi(__stack_top)
    addi  sp, sp, %lo(__stack_top)
    lui   t0, %hi(__bss_start)
    addi  t0, t0, %lo(__bss_start)
    lui   t1, %hi(__bss_end)
    addi  t1, t1, %lo(__bss_end)
clear_bss:
    blt   t0, t1, clear_word
    jal   x0, call_main
clear_word:
    sw    x0, 0(t0)
    addi  t0, t0, 4
    jal   x0, clear_bss
call_main:
    jal   ra, main
    .global halt
halt:
    beq   x0, x0, halt
