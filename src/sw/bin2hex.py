#!/usr/bin/env python3
"""Turn a raw binary image into a $readmemh file: one 32-bit little-endian word per line
(spec 08-software-flow.md). Fails if the image does not fit the RAM."""

import argparse
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("bin", type=Path)
    ap.add_argument("hex", type=Path)
    ap.add_argument("--ram-bytes", type=int, required=True)
    a = ap.parse_args()
    data = a.bin.read_bytes()
    if len(data) > a.ram_bytes:
        print(f"{a.bin}: {len(data)} bytes does not fit the {a.ram_bytes}-byte RAM "
              "(decision D1)", file=sys.stderr)
        return 1
    data += bytes(-len(data) % 4)
    words = [int.from_bytes(data[i:i + 4], "little") for i in range(0, len(data), 4)]
    a.hex.write_text("".join(f"{w:08x}\n" for w in words))
    print(f"{a.hex.name}: {len(words)} words ({len(data)} of {a.ram_bytes} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
