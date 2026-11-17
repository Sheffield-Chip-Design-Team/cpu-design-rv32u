#!/usr/bin/env python3
"""Check that DESIGN.md answers every design decision (make design-check).

Every section `## Dn ...` must exist for D1-D8, and every `- **Field:** value` line in
it must have a value that is not the template's _italic prompt_.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DECISIONS = [f"D{i}" for i in range(1, 9)]
FIELD = re.compile(r"^- \*\*(.+?):\*\*\s*(.*)$")


def unanswered(value: str) -> bool:
    v = value.strip()
    return not v or (v.startswith("_") and v.endswith("_"))


def main() -> int:
    path = ROOT / "DESIGN.md"
    text = path.read_text()
    sections = {m.group(1): m.start() for m in re.finditer(r"^## (D\d+)\b", text, re.M)}
    problems = []
    for d in DECISIONS:
        if d not in sections:
            problems.append(f"{d}: section missing")
            continue
        start = sections[d]
        later = [s for s in sections.values() if s > start]
        body = text[start:min(later) if later else len(text)]
        fields = [FIELD.match(line) for line in body.splitlines()]
        fields = [f for f in fields if f]
        if not fields:
            problems.append(f"{d}: no answers")
        for f in fields:
            if unanswered(f.group(2)):
                problems.append(f"{d}: '{f.group(1)}' is not answered")
    name = re.search(r"^Name\(s\):\s*(.*)$", text, re.M)
    if not name or unanswered(name.group(1)):
        problems.append("Name(s) is not filled in")
    if problems:
        print(f"{path.name}: {len(problems)} item(s) to answer:")
        print("\n".join(f"  {p}" for p in problems))
        return 1
    print(f"{path.name}: all {len(DECISIONS)} design decisions answered")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
