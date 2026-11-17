#!/usr/bin/env python3
"""Render the WaveDrom timing diagrams in docs/assets/wavedrom/*.json to SVG.

The site and the PDF both use the rendered SVGs (docs/assets/img/wavedrom/*.svg), so a
page needs no JavaScript and the PDF build needs no browser. Edit the .json source, then:

    uv run --group docs scripts/render-wavedrom.py           # (re)render every diagram
    uv run --group docs scripts/render-wavedrom.py --check   # fail if an SVG is stale

The JSON is WaveJSON (https://wavedrom.com/tutorial.html); paste it into
https://wavedrom.com/editor.html to edit it interactively.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import wavedrom

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "assets" / "wavedrom"
OUT = ROOT / "docs" / "assets" / "img" / "wavedrom"


def render(src: Path) -> str:
    return wavedrom.render(src.read_text()).tostring()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="only check that every SVG is up to date")
    args = ap.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    stale = []
    for src in sorted(SRC.glob("*.json")):
        svg, dst = render(src), OUT / f"{src.stem}.svg"
        if args.check:
            if not dst.exists() or dst.read_text() != svg:
                stale.append(dst.relative_to(ROOT))
        else:
            dst.write_text(svg)
            print(f"{src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")
    orphans = {p.stem for p in OUT.glob("*.svg")} - {p.stem for p in SRC.glob("*.json")}
    for name in sorted(orphans):
        print(f"warning: {OUT.relative_to(ROOT)}/{name}.svg has no source", file=sys.stderr)
    if stale:
        print("stale (run scripts/render-wavedrom.py):\n  " + "\n  ".join(map(str, stale)), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
