# 2. ISA and architectural state

## The 14 instructions

RV32u implements exactly these RV32I instructions. Any other encoding, including the rest of RV32I, is **illegal** and traps ([trap rule](06-retire-and-trap.md)).

| Format | Mnemonic | Opcode `[6:0]` | `funct3` | `funct7` | Operation | Role in compiled code |
|---|---|---|---|---|---|---|
| R | `ADD` | `0110011` | `000` | `0000000` | `rd = rs1 + rs2` | addition, pointer arithmetic |
| R | `SUB` | `0110011` | `000` | `0100000` | `rd = rs1 - rs2` | subtraction |
| R | `AND` | `0110011` | `111` | `0000000` | `rd = rs1 & rs2` | masking |
| R | `OR` | `0110011` | `110` | `0000000` | `rd = rs1 \| rs2` | combining bits |
| R | `SLT` | `0110011` | `010` | `0000000` | `rd = (rs1 < rs2) ? 1 : 0`, signed | comparisons |
| I | `ADDI` | `0010011` | `000` | | `rd = rs1 + imm_i` | constants, `sp` adjustment, `nop`, `mv` |
| I | `LW` | `0000011` | `010` | | `rd = Mem32[rs1 + imm_i]` | reading variables and stack frames |
| I | `JALR` | `1100111` | `000` | | `rd = PC + 4; PC = (rs1 + imm_i) & ~1` | returns (`ret`), function pointers |
| S | `SW` | `0100011` | `010` | | `Mem32[rs1 + imm_s] = rs2` | writing variables, saving registers |
| B | `BEQ` | `1100011` | `000` | | `if (rs1 == rs2) PC += imm_b` | equality tests, loops |
| B | `BLT` | `1100011` | `100` | | `if (rs1 < rs2) PC += imm_b`, signed | `for (i = 0; i < n; i++)` |
| U | `LUI` | `0110111` | | | `rd = imm_u` | 32-bit constants (with `ADDI`) |
| U | `AUIPC` | `0010111` | | | `rd = PC + imm_u` | PC-relative addressing |
| J | `JAL` | `1101111` | | | `rd = PC + 4; PC += imm_j` | calls (`call`), jumps (`j`) |

`PC` in the table is the address of the instruction itself. All arithmetic is modulo 2^32.

## Immediates

Every immediate is sign-extended to 32 bits from `inst[31]`:

| Format | Immediate |
|---|---|
| I | `{{20{inst[31]}}, inst[31:20]}` |
| S | `{{20{inst[31]}}, inst[31:25], inst[11:7]}` |
| B | `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` |
| U | `{inst[31:12], 12'b0}` |
| J | `{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` |

The register fields are always at the same bits: `rd = inst[11:7]`, `rs1 = inst[19:15]`, `rs2 = inst[24:20]`.

## Architectural state

- **Registers:** 32 general-purpose 32-bit registers, `x0`-`x31`. `x0` always reads as zero, and writes to it are ignored. The reset value of `x1`-`x31` is **unspecified**: software must write a register before reading it. The provided start-up code clears them all ([software flow](08-software-flow.md)).
- **PC:** a 32-bit register, `0x0000_0000` after reset.
- **Memory:** byte-addressed and little-endian. RV32u accesses only whole words: every instruction fetch and every `LW`/`SW` address must be word aligned (`addr[1:0] == 2'b00`), or the instruction traps.
- **No other state:** there are no CSRs, interrupts or privilege levels.

## Requirements

- R2.1: The core must execute the 14 instructions exactly as above.
- R2.2: `x0` must read as zero after any write to it.
- R2.3: The PC must be `0x0000_0000` after reset; execution starts there.
- R2.4: Any encoding not in the table must trap. So must any misaligned fetch or `LW`/`SW` ([chapter 6](06-retire-and-trap.md)).

## Check yourself

1. `jalr x1, x10, 0` sits at PC `0x8` and `x10` holds 21. What does it write to `x1`, and where does it jump?

   <details><summary>Answer</summary>
   `x1 = 0xC` (PC + 4), and the PC becomes 20: (21 + 0) & ~1. Bit 0 is cleared, so an odd target is still word aligned only if bit 1 is also 0. 20 is aligned, but 22 would trap at the fetch.
   </details>

2. Which immediate does `sw x6, -4(x5)` use, and what are its bits `inst[31:25]` and `inst[11:7]`?

   <details><summary>Answer</summary>
   The S-type immediate. -4 is `0xFFC` in 12 bits, so `inst[31:25] = 1111111` and `inst[11:7] = 11100`.
   </details>
