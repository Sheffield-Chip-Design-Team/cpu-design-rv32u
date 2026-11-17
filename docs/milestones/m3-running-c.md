# M3: Running C

You'll choose the chip's memory (D1), run the provided C programs on your core, and write and run a C program of your own.

## Before you start

- Finish [M2](m2-datapath-fsm.md): every per-instruction test passes.
- Read [Memory subsystem](../spec/07-memory-subsystem.md), [Software flow](../spec/08-software-flow.md) and [Verification](../spec/09-verification.md).

Time: about 6 hours.

## Part 1: Choose the memory (D1)

1. Compare the three options in [chapter 7](../spec/07-memory-subsystem.md#the-ram-options). Estimate the flip-flop option's cost with `scripts/select-memory.py flops --words 64`, then switch back.
2. Apply your choice: `scripts/select-memory.py <option>`, then `make -C sw clean`.
3. Record the option and your reasons in `DESIGN.md` (D1).

You should see: `scripts/select-memory.py --show` prints your option, and `make isa` still passes.

## Part 2: Run the C programs

1. Run `make c`.
2. Look at one program's journey: `sw/c/fib.c` becomes `sw/build/c/fib.s`, then `fib.legal.s` (the legalizer's rewrites), then the disassembly `fib.lst`.

You should see each program pass, with its CPI in the log, for example:

```
fib: 4456 instructions in 24975 cycles (CPI 5.60)
...
** TESTS=5 PASS=5 FAIL=0 SKIP=0 ...
```

Predict before you look: which instruction does `fib` execute most often?

<details><summary>Answer</summary>
`lw` and `sw`, for the stack frames: at `-O0`, GCC keeps every local variable in memory. Count them in `fib.lst` and the log's instruction total.
</details>

## Part 3: A program of your own (required)

1. Write `sw/c/<name>.c` that computes something you can check by hand: a checksum, a small matrix sum, a recursive sequence. Store the results in a `volatile int result[]`, and add an `// expect:` line ([chapter 8](../spec/08-software-flow.md#adding-a-program)).
2. Run `make -C sw`. If `check_subset.py` rejects an instruction, rewrite that C ([Writing C for RV32u](../spec/08-software-flow.md#writing-c-for-rv32u)).
3. Run `make c`.

You should see: your program in the list, passing.

## Finishing

You're done when:

- `make c` passes, including your program;
- `DESIGN.md` D1 is answered.

Questions:

1. Your memory option holds how many words? How much of it does your largest program (code + data + stack) use?
2. Why does the legalizer turn `slli rd, rs, 2` into two `add`s rather than one?

Submit: commit your work.

Next on the Course path: read [Tiny Tapeout integration](../spec/10-tiny-tapeout.md) and [Deliverables and acceptance](../spec/11-deliverables.md).
