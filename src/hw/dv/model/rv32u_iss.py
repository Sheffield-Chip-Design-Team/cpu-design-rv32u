"""RV32u (RV32I-Micro) reference model: an instruction-set simulator of the 14-instruction
subset, the trap rule and the memory map (docs/spec/).

It is the oracle for the provided tests: every instruction the RTL retires is compared
with `Rv32uIss.step()` (src/hw/dv/harness.py). It is also the decoder `src/sw/check_subset.py`
uses to reject compiled code outside the subset, so the definition of "legal" lives in
one place.

Memory map (spec 07-memory-subsystem.md):
  [0, ram_bytes)   RAM (word access only)
  addr[31] = 1     I/O region: reads 0, writes ignored (the starter's rv32u_io; the
                   provided tests never touch it)
  otherwise        unmapped: reads 0, writes ignored
Trap rule (spec 06-retire-and-trap.md): an illegal or unsupported instruction, a fetch
from a PC with PC[1:0] != 0, or an LW/SW to an address with addr[1:0] != 0 retires with
trap set, and the core stops.
"""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass

M32 = 0xFFFF_FFFF
IO_BASE = 0x8000_0000

OP_LUI, OP_AUIPC, OP_JAL, OP_JALR = 0b0110111, 0b0010111, 0b1101111, 0b1100111
OP_BRANCH, OP_LOAD, OP_STORE, OP_IMM, OP_REG = 0b1100011, 0b0000011, 0b0100011, 0b0010011, 0b0110011

REG_NAMES = ["zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2",
             "a3", "a4", "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9",
             "s10", "s11", "t3", "t4", "t5", "t6"]

def sx(value: int, bits: int) -> int:
    """Sign-extend `bits` bits of value to a Python int."""
    value &= (1 << bits) - 1
    return value - (1 << bits) if value >> (bits - 1) else value


def to_signed(v: int) -> int:
    return sx(v, 32)


@dataclass(frozen=True)
class Decoded:
    name: str
    rd: int
    rs1: int
    rs2: int
    imm: int  # sign-extended (Python int)

    def text(self, pc: int | None = None) -> str:
        r = REG_NAMES
        n, rd, rs1, rs2, imm = self.name, self.rd, self.rs1, self.rs2, self.imm
        if n in ("add", "sub", "and", "or", "slt"):
            return f"{n} {r[rd]}, {r[rs1]}, {r[rs2]}"
        if n in ("addi", "jalr"):
            return f"{n} {r[rd]}, {r[rs1]}, {imm}"
        if n == "lw":
            return f"lw {r[rd]}, {imm}({r[rs1]})"
        if n == "sw":
            return f"sw {r[rs2]}, {imm}({r[rs1]})"
        if n in ("beq", "blt"):
            tgt = f"0x{(pc + imm) & M32:x}" if pc is not None else f"pc{imm:+d}"
            return f"{n} {r[rs1]}, {r[rs2]}, {tgt}"
        if n in ("lui", "auipc"):
            return f"{n} {r[rd]}, 0x{(imm >> 12) & 0xFFFFF:x}"
        tgt = f"0x{(pc + imm) & M32:x}" if pc is not None else f"pc{imm:+d}"
        return f"jal {r[rd]}, {tgt}"


def decode(insn: int) -> Decoded | None:
    """Decode one instruction word; None if it is not one of the 14."""
    op = insn & 0x7F
    rd = (insn >> 7) & 0x1F
    f3 = (insn >> 12) & 0x7
    rs1 = (insn >> 15) & 0x1F
    rs2 = (insn >> 20) & 0x1F
    f7 = insn >> 25
    imm_i = sx(insn >> 20, 12)
    imm_s = sx(((insn >> 25) << 5) | ((insn >> 7) & 0x1F), 12)
    imm_b = sx((((insn >> 31) & 1) << 12) | (((insn >> 7) & 1) << 11)
               | (((insn >> 25) & 0x3F) << 5) | (((insn >> 8) & 0xF) << 1), 13)
    imm_u = sx(insn & 0xFFFFF000, 32)
    imm_j = sx((((insn >> 31) & 1) << 20) | (((insn >> 12) & 0xFF) << 12)
               | (((insn >> 20) & 1) << 11) | (((insn >> 21) & 0x3FF) << 1), 21)
    if op == OP_REG:
        names = {(0, 0): "add", (0, 0x20): "sub", (7, 0): "and", (6, 0): "or", (2, 0): "slt"}
        name = names.get((f3, f7))
        return Decoded(name, rd, rs1, rs2, 0) if name else None
    if op == OP_IMM and f3 == 0:
        return Decoded("addi", rd, rs1, 0, imm_i)
    if op == OP_LOAD and f3 == 2:
        return Decoded("lw", rd, rs1, 0, imm_i)
    if op == OP_JALR and f3 == 0:
        return Decoded("jalr", rd, rs1, 0, imm_i)
    if op == OP_STORE and f3 == 2:
        return Decoded("sw", 0, rs1, rs2, imm_s)
    if op == OP_BRANCH and f3 in (0, 4):
        return Decoded("beq" if f3 == 0 else "blt", 0, rs1, rs2, imm_b)
    if op == OP_LUI:
        return Decoded("lui", rd, 0, 0, imm_u)
    if op == OP_AUIPC:
        return Decoded("auipc", rd, 0, 0, imm_u)
    if op == OP_JAL:
        return Decoded("jal", rd, 0, 0, imm_j)
    return None


def disassemble(insn: int, pc: int | None = None) -> str:
    d = decode(insn)
    return d.text(pc) if d else f".word 0x{insn:08x}  # not in RV32u"


@dataclass(frozen=True)
class Retire:
    """What one retired instruction did: the fields of the retire port (spec 06)."""

    pc: int
    insn: int
    pc_next: int
    rd_addr: int = 0          # 0 when no register is written (or rd is x0)
    rd_wdata: int = 0
    mem_addr: int = 0         # LW/SW only
    mem_wstrb: int = 0        # 0b1111 for SW
    mem_wdata: int = 0        # SW only
    mem_rdata: int = 0        # LW only
    trap: bool = False

    @property
    def name(self) -> str:
        d = decode(self.insn)
        return d.name if d else "illegal"

    @property
    def halts(self) -> bool:
        """A trap, or an instruction that jumps to itself (crt0's `halt: beq x0, x0, halt`)."""
        return self.trap or self.pc_next == self.pc


class Rv32uIss:
    def __init__(self, ram_bytes: int = 2048) -> None:
        if ram_bytes % 4:
            raise ValueError("RAM size must be whole words")
        self.ram_bytes = ram_bytes
        self.ram = [0] * (ram_bytes // 4)
        self.x = [0] * 32
        self.pc = 0
        self.trapped = False
        self.retired = 0

    # ---- memory ---------------------------------------------------------------------
    def load_words(self, words: Iterable[int], base: int = 0) -> None:
        for i, w in enumerate(words):
            self.ram[base // 4 + i] = w & M32

    def read(self, addr: int) -> int:
        if addr < self.ram_bytes:
            return self.ram[addr >> 2]
        return 0  # I/O region or unmapped

    def write(self, addr: int, value: int) -> None:
        if addr < self.ram_bytes:
            self.ram[addr >> 2] = value & M32

    def word(self, addr: int) -> int:
        """A RAM word, for checking results."""
        return self.ram[addr >> 2]

    # ---- execution --------------------------------------------------------------------
    def step(self) -> Retire:
        if self.trapped:
            raise RuntimeError("the core has trapped; reset it to run again")
        pc = self.pc
        self.retired += 1
        if pc & 3:
            self.trapped = True
            return Retire(pc, 0, pc, trap=True)
        insn = self.read(pc)
        d = decode(insn)
        if d is None:
            self.trapped = True
            return Retire(pc, insn, pc, trap=True)
        x = self.x
        a, b = x[d.rs1], x[d.rs2]
        nxt = (pc + 4) & M32
        rd_val: int | None = None
        mem = {}
        n = d.name
        if n == "add":
            rd_val = a + b
        elif n == "sub":
            rd_val = a - b
        elif n == "and":
            rd_val = a & b
        elif n == "or":
            rd_val = a | b
        elif n == "slt":
            rd_val = int(to_signed(a) < to_signed(b))
        elif n == "addi":
            rd_val = a + d.imm
        elif n == "lui":
            rd_val = d.imm
        elif n == "auipc":
            rd_val = pc + d.imm
        elif n == "jal":
            rd_val, nxt = pc + 4, (pc + d.imm) & M32
        elif n == "jalr":
            rd_val, nxt = pc + 4, (a + d.imm) & M32 & ~1
        elif n in ("beq", "blt"):
            taken = a == b if n == "beq" else to_signed(a) < to_signed(b)
            if taken:
                nxt = (pc + d.imm) & M32
        elif n in ("lw", "sw"):
            addr = (a + d.imm) & M32
            if addr & 3:
                self.trapped = True
                return Retire(pc, insn, pc, trap=True)
            if n == "lw":
                rd_val = self.read(addr)
                mem = {"mem_addr": addr, "mem_rdata": rd_val}
            else:
                self.write(addr, b)
                mem = {"mem_addr": addr, "mem_wstrb": 0b1111, "mem_wdata": b}
        rd_addr = rd_wdata = 0
        if rd_val is not None and d.rd != 0:
            rd_addr, rd_wdata = d.rd, rd_val & M32
            x[d.rd] = rd_wdata
        self.pc = nxt
        return Retire(pc, insn, nxt, rd_addr, rd_wdata, trap=False, **mem)

    def run(self, max_steps: int = 1_000_000) -> list[Retire]:
        """Run to a halt (trap or self-loop); the retire records in order."""
        out = []
        for _ in range(max_steps):
            r = self.step()
            out.append(r)
            if r.halts:
                return out
        raise TimeoutError(f"no halt within {max_steps} instructions (pc=0x{self.pc:x})")
