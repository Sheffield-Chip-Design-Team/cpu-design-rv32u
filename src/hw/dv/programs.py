"""The provided test programs: their images, symbols and expected results.

Each program in src/sw/isa/*.S or src/sw/c/*.c has an `expect:` comment, e.g.
    # expect: x5=0x00000005 mem[0x204]=0x63      (ISA tests: registers and RAM words)
    # expect: trap@0x00000008                    (the instruction at 0x8 must trap)
    // expect: result[0]=55 result[1]=610       (C tests: words of a global, by symbol)
`src/sw/Makefile` builds them into src/sw/build/{isa,c}/<name>.{hex,sym,lst}.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SW = ROOT / "src" / "sw"
MEM_CONFIG = ROOT / "src" / "hw" / "rtl" / "mem_ss" / "mem_config.svh"
BUILD = SW / "build"

_EXPECT = re.compile(r"(?:#|//)\s*expect:\s*(.*)")


def ram_words() -> int:
    m = re.search(r"`define RV32U_RAM_WORDS (\d+)", MEM_CONFIG.read_text())
    if not m:
        raise RuntimeError(f"{MEM_CONFIG.relative_to(ROOT)} has no RV32U_RAM_WORDS (decision D1)")
    return int(m.group(1))


@dataclass
class Program:
    kind: str  # isa | c
    name: str
    source: Path
    regs: dict[int, int] = field(default_factory=dict)
    mem: dict[int, int] = field(default_factory=dict)
    symbols_expected: dict[str, int] = field(default_factory=dict)  # "result[1]" -> value
    trap_pc: int | None = None

    @property
    def hex(self) -> Path:
        return BUILD / self.kind / f"{self.name}.hex"

    @property
    def lst(self) -> Path:
        return BUILD / self.kind / f"{self.name}.lst"

    def words(self) -> list[int]:
        if not self.hex.exists():
            raise FileNotFoundError(f"{self.hex} is missing: run `make -C sw`")
        return [int(w, 16) for w in self.hex.read_text().split()]

    def symbols(self) -> dict[str, int]:
        out = {}
        sym = BUILD / self.kind / f"{self.name}.sym"
        for line in sym.read_text().splitlines():
            parts = line.split()
            if len(parts) == 3:
                out[parts[2]] = int(parts[0], 16)
        return out

    def expected_words(self) -> dict[int, int]:
        """Every expected RAM word, symbols resolved to addresses."""
        out = dict(self.mem)
        if self.symbols_expected:
            syms = self.symbols()
            for name, value in self.symbols_expected.items():
                base, _, idx = name.partition("[")
                if base not in syms:
                    raise KeyError(f"{self.name}: no symbol '{base}'")
                out[syms[base] + 4 * int(idx.rstrip("]") or 0)] = value
        return out


def _int(s: str) -> int:
    return int(s, 0) & 0xFFFF_FFFF


def parse(kind: str, source: Path) -> Program:
    p = Program(kind, source.stem, source)
    for line in source.read_text().splitlines():
        m = _EXPECT.search(line)
        if not m:
            continue
        for item in m.group(1).split():
            if item.startswith("trap@"):
                p.trap_pc = int(item[5:], 0)
                continue
            key, eq, value = item.partition("=")
            if not eq:
                raise ValueError(f"{source.name}: cannot read expectation '{item}'")
            if re.fullmatch(r"x\d+", key):
                p.regs[int(key[1:])] = _int(value)
            elif key.startswith("mem[") and key.endswith("]"):
                p.mem[int(key[4:-1], 0)] = _int(value)
            elif re.fullmatch(r"[A-Za-z_]\w*(\[\d+\])?", key):
                p.symbols_expected[key] = _int(value)
            else:
                raise ValueError(f"{source.name}: cannot read expectation '{item}'")
    return p


def programs(kind: str) -> list[Program]:
    pattern = "*.S" if kind == "isa" else "*.c"
    return [parse(kind, f) for f in sorted((SW / kind).glob(pattern))]


def program_enum(kind: str) -> type[Enum]:
    """The programs of one kind as an Enum, so cocotb.parametrize names each test after
    its program (it only uses short strings, but any Enum member's name)."""
    return Enum(f"{kind.capitalize()}Program", {p.name: p.name for p in programs(kind)})
