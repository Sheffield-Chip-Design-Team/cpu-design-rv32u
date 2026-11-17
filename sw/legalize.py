#!/usr/bin/env python3
"""Rewrite GCC -O0 assembly so it only uses RV32u's 14 instructions (spec 08).

GCC targets the whole of RV32I. At -O0 on int-only code, the instructions it uses that
RV32u lacks are few, and each has a short equivalent in the subset:

  bne  a, b, L     ->  beq a, b, 1f ; jal x0, L ; 1:
  bge  a, b, L     ->  blt a, b, 1f ; jal x0, L ; 1:        (ble a, b, L = bge b, a, L)
  bnez/bgez/blez   ->  the same with x0
  slli rd, rs, k   ->  add rd, rs, rs ; then k-1 x add rd, rd, rd      (k = 0: mv)
  seqz rd, rs      ->  beq rs, x0, 1f ; addi rd, x0, 0 ; jal x0, 2f ; 1: addi rd, x0, 1 ; 2:
  snez rd, rs      ->  the same with 1 and 0 swapped
  andi rd, rd, 255 (or 1) straight after seqz/snez rd: dropped (the value is already 0/1;
                   GCC emits it for `return a == b;`)

Everything else passes through unchanged; sw/check_subset.py then rejects anything still
outside the subset (e.g. unsigned compares, shifts by a register, mul) with the source
line, so you can rewrite that C.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

INSN = re.compile(r"^(\s*)([a-z][a-z0-9.]*)\s+(.*?)\s*(#.*)?$")


class Legalizer:
    def __init__(self) -> None:
        self.n = 0
        self.rewrites: dict[str, int] = {}
        self.bool_rd: str | None = None  # rd of the last seqz/snez, if it was the last insn

    def label(self) -> str:
        self.n += 1
        return f".Lrv32u_{self.n}"

    def note(self, mnemonic: str) -> None:
        self.rewrites[mnemonic] = self.rewrites.get(mnemonic, 0) + 1

    def branch_over(self, ind: str, cond: str, a: str, b: str, target: str) -> list[str]:
        skip = self.label()
        return [f"{ind}{cond}\t{a},{b},{skip}", f"{ind}jal\tx0,{target}", f"{skip}:"]

    def line(self, text: str) -> list[str]:
        m = INSN.match(text)
        if not m:
            if text.strip().endswith(":"):  # a label: control can arrive from elsewhere
                self.bool_rd = None
            return [text]
        ind, op, args, _comment = m.groups()
        ops = [o.strip() for o in args.split(",")] if args else []
        ind = ind or "\t"
        bool_rd, self.bool_rd = self.bool_rd, None
        if (op == "andi" and len(ops) == 3 and bool_rd is not None and ops[0] == ops[1] == bool_rd
                and int(ops[2], 0) in (1, 255)):
            self.note("andi (after seqz/snez)")
            return [f"{ind}# andi {args} dropped: the value is already 0 or 1"]
        if op == "bne" and len(ops) == 3:
            self.note(op)
            return self.branch_over(ind, "beq", ops[0], ops[1], ops[2])
        if op == "bnez" and len(ops) == 2:
            self.note(op)
            return self.branch_over(ind, "beq", ops[0], "zero", ops[1])
        if op == "bge" and len(ops) == 3:
            self.note(op)
            return self.branch_over(ind, "blt", ops[0], ops[1], ops[2])
        if op == "ble" and len(ops) == 3:
            self.note(op)
            return self.branch_over(ind, "blt", ops[1], ops[0], ops[2])
        if op == "bgez" and len(ops) == 2:
            self.note(op)
            return self.branch_over(ind, "blt", ops[0], "zero", ops[1])
        if op == "blez" and len(ops) == 2:
            self.note(op)
            return self.branch_over(ind, "blt", "zero", ops[0], ops[1])
        if op == "slli" and len(ops) == 3:
            self.note(op)
            rd, rs, k = ops[0], ops[1], int(ops[2], 0)
            if k == 0:
                return [f"{ind}addi\t{rd},{rs},0"]
            return [f"{ind}add\t{rd},{rs},{rs}"] + [f"{ind}add\t{rd},{rd},{rd}"] * (k - 1)
        if op in ("seqz", "snez") and len(ops) == 2:
            self.note(op)
            rd, rs = ops
            is_zero, done = self.label(), self.label()
            then, other = ("1", "0") if op == "seqz" else ("0", "1")
            self.bool_rd = rd
            return [f"{ind}beq\t{rs},zero,{is_zero}", f"{ind}addi\t{rd},zero,{other}",
                    f"{ind}jal\tx0,{done}", f"{is_zero}:", f"{ind}addi\t{rd},zero,{then}",
                    f"{done}:"]
        return [text]


def legalize(source: str) -> tuple[str, dict[str, int]]:
    lg = Legalizer()
    out: list[str] = []
    for text in source.splitlines():
        out += lg.line(text)
    return "\n".join(out) + "\n", lg.rewrites


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("asm", type=Path)
    ap.add_argument("-o", "--output", type=Path, required=True)
    a = ap.parse_args()
    text, rewrites = legalize(a.asm.read_text())
    a.output.write_text(text)
    summary = ", ".join(f"{k} x{v}" for k, v in sorted(rewrites.items())) or "nothing"
    print(f"{a.output.name}: rewrote {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
