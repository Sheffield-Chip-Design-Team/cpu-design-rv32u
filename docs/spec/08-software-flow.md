# 8. Software flow

RV32u runs C compiled by GCC for `rv32i`. `src/sw/Makefile` turns each program into a RAM image:

```
C source --gcc -O0 -S--> assembly --legalize.py--> RV32u assembly --gcc--> ELF
   --check_subset.py--> (fails if any instruction is outside the 14)
   --objcopy--> binary --bin2hex.py--> src/sw/build/<kind>/<name>.hex  ($readmemh, one word per line)
```

`make sw` (or `make -C sw`) builds every ISA test (`src/sw/isa/*.S`) and C program (`src/sw/c/*.c`). Each also gets a disassembly (`.lst`) and a symbol table (`.sym`) in `src/sw/build/`.

## Toolchain

Any of `riscv32-unknown-elf-`, `riscv64-unknown-elf-` or `riscv-none-elf-` GCC works (`scripts/install-riscv-prebuilt.sh`). The 64-bit toolchains target RV32 with these flags:

```
-march=rv32i -mabi=ilp32 -O0 -ffreestanding -fno-builtin -nostdlib -nostartfiles
-mno-relax -Wl,--no-relax
```

There is no C library: no `printf`, `malloc` or `memcpy`. `--no-relax` stops the linker from rewriting addresses relative to `gp`, which `crt0` does not set up.

## Start-up and linking

`src/sw/crt0.S`, using only RV32u instructions:

1. clears `x1`-`x31` (their reset value is unspecified, and GCC saves callee-saved registers it has never written);
2. sets `sp` to the top of the RAM (`__stack_top`);
3. clears `.bss`;
4. calls `main()`;
5. halts in `halt: beq x0, x0, halt`.

`src/sw/link.ld.in` places `.text` at address 0, followed by `.rodata`, `.data` and `.bss`. The RAM size comes from your memory option (D1).

## Legalizing GCC's output

At `-O0` on `int` code, GCC uses a few RV32I instructions that RV32u lacks. `src/sw/legalize.py` rewrites them into the subset:

| GCC writes | RV32u sequence | Why GCC uses it |
|---|---|---|
| `bne a, b, L` | `beq a, b, 1f ; jal x0, L ; 1:` | `if (x == y)`, `while (x != y)` |
| `bge a, b, L` (and `ble`) | `blt a, b, 1f ; jal x0, L ; 1:` | `if (a < b)` |
| `bnez`, `bgez`, `blez` | as above, with `x0` | comparisons with 0 |
| `slli rd, rs, k` | `k` x `add` (doubling) | `a[i]`: index x 4 |
| `seqz` / `snez rd, rs` | a branch and two `addi` | `return a == b;` |
| `andi rd, rd, 255` after `seqz`/`snez` | dropped (the value is already 0 or 1) | the conversion to `int` |

`src/sw/check_subset.py` then decodes every instruction of the linked program, using the reference model's own decoder, and fails the build on any that is outside the subset. It prints the address and the instruction.

## Writing C for RV32u

- Use `int` (and `int` arrays and pointers). No `char`, `short` or `unsigned` comparisons: those need byte loads or `bltu`/`bgeu`.
- No `*`, `/`, `%`, `<<` or `>>` by a variable: there is no multiplier or shifter. Use loops (see `src/sw/c/gcd.c`).
- No struct copies or large initialized local arrays: GCC calls `memcpy` for them.
- Keep the code, data and stack within the RAM (D1).

If `check_subset.py` rejects a program, the message names the instruction. Rewrite that C, or extend `legalize.py` if the rewrite is safe.

## Adding a program

Put `src/sw/c/<name>.c` (or `src/sw/isa/<name>.S`) next to the others, with an `expect:` comment giving its results:

```c
// expect: result[0]=55 result[1]=610
volatile int result[2];
```

ISA tests use `# expect: x5=0x00000005 mem[0x204]=0x63` (registers and RAM words) or `# expect: trap@0x00000008`. The provided tests pick up every program in `src/sw/c/` and `src/sw/isa/` automatically ([chapter 9](09-verification.md)).
