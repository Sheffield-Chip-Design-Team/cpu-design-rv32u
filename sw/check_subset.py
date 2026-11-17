#!/usr/bin/env python3
"""Fail if a linked program uses any instruction outside RV32u's 14 (spec 08).

It decodes every instruction word of the ELF's code with the reference model's own
decoder (verif/model/rv32u_iss.py), so "legal" means exactly what the tests check.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from verif.model.rv32u_iss import decode  # noqa: E402

LINE = re.compile(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(.*)$")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("elf", type=Path)
    ap.add_argument("--objdump", default="riscv64-unknown-elf-objdump")
    a = ap.parse_args()
    dump = subprocess.run([a.objdump, "-d", "-M", "no-aliases,numeric", str(a.elf)],
                          check=True, capture_output=True, text=True).stdout
    bad, count = [], 0
    for text in dump.splitlines():
        m = LINE.match(text)
        if not m:
            continue
        count += 1
        if decode(int(m.group(2), 16)) is None:
            bad.append(f"  0x{int(m.group(1), 16):04x}: {m.group(3).strip()}")
    if bad:
        print(f"{a.elf.name}: {len(bad)} instruction(s) outside RV32u:", file=sys.stderr)
        print("\n".join(bad[:20]), file=sys.stderr)
        print("Rewrite the C so GCC avoids them (spec 08: no unsigned compares, no "
              "shifts by a variable, no *, /, %, char or short), or extend "
              "sw/legalize.py.", file=sys.stderr)
        return 1
    print(f"{a.elf.name}: {count} instructions, all RV32u")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
