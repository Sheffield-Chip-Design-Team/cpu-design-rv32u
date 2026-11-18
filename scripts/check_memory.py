#!/usr/bin/env python3
"""Check that your RAM (design decision D1) and the files that describe it agree.

    make mem-check          (uv run python scripts/check_memory.py)

You build the memory subsystem yourself (src/hw/rtl/mem_ss/, and SRAM macro wrappers in
src/hw/pd/wrappers/), and then describe it by hand in four places: the RAM_WORDS
parameter of rv32u_mem_ss.sv (its size), the FuseSoC cores, info.yaml (source files, tiles) and src/config.json (macro
placement and power). This script checks them against each other and against the RTL:

  - RAM_WORDS is a power of two the RAM can hold;
  - info.yaml lists exactly the sources FuseSoC builds (the lint target), and they exist;
  - every IHP SRAM macro instance in the RTL, traced from tt_um_sharc_rv32u, appears in
    config.json's MACROS with exactly that hierarchical path, and in
    PDN_MACRO_CONNECTIONS on both supplies, with the SRAM power step and PDN_CFG set;
  - with no macros (flip-flops), config.json has no MACROS, and the area fits the tiles.

It reads the RTL with regular expressions, not a full parser, so it is a check, not a
proof: the GDS action is the final word.
"""

from __future__ import annotations

import json
import math
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
MEM_SS = SRC / "hw/rtl/mem_ss/rv32u_mem_ss.sv"
TOP = "tt_um_sharc_rv32u"

#: The IHP macros RV32u may use: words, bits per word, area in um^2
MACROS = {
    "RM_IHPSG13_1P_512x32_c2_bm_bist": (512, 32, 416.64 * 191.34),
    "RM_IHPSG13_1P_512x16_c2_bm_bist": (512, 16, 236.80 * 191.34),
}
SUPPLIES = ("VDD!", "VDDARRAY!")

# Tiny Tapeout IHP tiles, and their area in gate equivalents
# (202.08 x 154.98 um / 7.2576 um^2 per sg13g2_nand2_1).
TILES = ["1x1", "1x2", "2x2", "3x2", "4x2", "6x2", "8x2", "3x4", "4x4", "5x4", "6x4", "8x4"]
TILE_UM2 = 202.08 * 154.98
UM2_PER_GE = 7.2576
CORE_GE = 17_000   # the reference CPU, memory adapter and I/O (Yosys, sg13g2 cells)
DENSITY = 0.6      # the fraction of the free area placement and routing can use

errors: list[str] = []


def ok(msg: str) -> None:
    print(f"  ok     {msg}")


def fail(msg: str) -> None:
    print(f"  ERROR  {msg}")
    errors.append(msg)


def warn(msg: str) -> None:
    print(f"  warn   {msg}")


def tiles_area(tiles: str) -> float:
    return math.prod(map(int, tiles.split("x"))) * TILE_UM2


# ---- RTL scanning -----------------------------------------------------------------------

def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def modules(files: list[Path]) -> dict[str, str]:
    """Module name -> body, from every file (skipping `ifndef SIM black boxes)."""
    out = {}
    for f in files:
        text = strip_comments(f.read_text())
        for m in re.finditer(r"\bmodule\s+(\w+)(.*?)\bendmodule\b", text, re.S):
            if "(* blackbox *)" in text[max(0, m.start() - 40):m.start()] or m.group(1) in MACROS:
                continue
            out[m.group(1)] = m.group(2)
    return out


_INST = re.compile(r"\b(\w+)\s*(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*)?\b(\w+)\s*\(")


def instances(body: str, known: set[str]) -> list[tuple[str, str]]:
    """(module, instance name) for every instantiation of a known module in `body`."""
    return [(m.group(1), m.group(2)) for m in _INST.finditer(body) if m.group(1) in known]


def macro_paths(mods: dict[str, str]) -> dict[str, list[str]]:
    """Every SRAM macro instance under the top level, as macro -> [hierarchical paths]."""
    known = set(mods) | set(MACROS)
    found: dict[str, list[str]] = {}

    def walk(module: str, path: list[str]) -> None:
        if module in MACROS:
            found.setdefault(module, []).append(".".join(path))
            return
        for child, name in instances(mods.get(module, ""), known):
            walk(child, path + [name])

    walk(TOP, [])
    return found


# ---- the checks ------------------------------------------------------------------------

def ram_words() -> int | None:
    m = re.search(r"parameter\s+int\s+RAM_WORDS\s*=\s*(\d+)", MEM_SS.read_text())
    if not m:
        fail(f"{MEM_SS.relative_to(ROOT)}: no `parameter int RAM_WORDS = <n>`")
        return None
    words = int(m.group(1))
    if words < 16 or words > 512 or words & (words - 1):
        fail(f"RAM_WORDS = {words}: use a power of two from 16 to 512")
    else:
        ok(f"RAM_WORDS = {words} ({words * 4} bytes)")
    return words


def fusesoc_sources() -> list[str] | None:
    """The sources FuseSoC builds for the Tiny Tapeout top level (the lint target)."""
    cmd = ["fusesoc", "--cores-root", "src/hw", "--cores-root", "ip", "run", "--no-export",
           "--setup", "--target=lint", "sharc:rv32u:soc"]
    run = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if run.returncode:
        fail("FuseSoC could not set up the lint target:\n" + run.stdout + run.stderr)
        return None
    eda = next((ROOT / "build/sharc_rv32u_soc_0.1.0/lint").glob("*.eda.yml"))
    build = eda.parent
    files = []
    for f in yaml.safe_load(eda.read_text())["files"]:
        if f.get("is_include_file") or not f["file_type"].startswith(("systemVerilog", "verilog")):
            continue
        files.append((build / f["name"]).resolve().relative_to(SRC).as_posix())
    return files


def main() -> int:
    print("RAM size")
    words = ram_words()

    print("Source files (info.yaml vs FuseSoC)")
    info = yaml.safe_load((ROOT / "info.yaml").read_text())
    listed = [str(s) for s in info["project"]["source_files"]]
    for s in listed:
        if not (SRC / s).exists():
            fail(f"info.yaml lists {s}, which does not exist in src/")
    built = fusesoc_sources()
    if built is not None:
        missing = [s for s in built if s not in listed]
        extra = [s for s in listed if s not in built]
        for s in missing:
            fail(f"FuseSoC builds {s}, but info.yaml source_files does not list it")
        for s in extra:
            fail(f"info.yaml lists {s}, but no FuseSoC core builds it (add it to its .core)")
        if not missing and not extra:
            ok(f"info.yaml and FuseSoC agree ({len(listed)} files)")
    for w in sorted((SRC / "hw/pd/wrappers").glob("*.sv")):
        rel = w.relative_to(SRC).as_posix()
        if rel not in listed:
            fail(f"{rel} is not in info.yaml (and probably not in rv32u_wrappers.core)")

    print("SRAM macros (RTL vs src/config.json)")
    config = json.loads((SRC / "config.json").read_text())
    mods = modules([SRC / s for s in listed if (SRC / s).exists()])
    if TOP not in mods:
        fail(f"no module {TOP} in the info.yaml sources")
        return report()
    found = macro_paths(mods)
    rtl_paths = {p: m for m, ps in found.items() for p in ps}
    cfg_macros = config.get("MACROS", {})
    cfg_paths = {p: m for m, v in cfg_macros.items() for p in v.get("instances", {})}

    if not rtl_paths:
        ok("no SRAM macros in the RTL: a flip-flop RAM")
        if cfg_macros:
            fail("config.json has MACROS, but the RTL instantiates no SRAM macro")
        if words:
            ge = CORE_GE + words * 32 * 7.25 + (words - 1) * 32 * 2.5
            need = ge * UM2_PER_GE / DENSITY
            have = tiles_area(info["project"]["tiles"])
            msg = (f"estimate: ~{ge / 1000:.0f}k GE, ~{need / 1000:.0f}k um^2 at "
                   f"{DENSITY:.0%} density; {info['project']['tiles']} tiles are "
                   f"{have / 1000:.0f}k um^2")
            (ok if need <= have else fail)(msg if need <= have else msg + ": use more tiles or fewer words")
        return report()

    for path, macro in sorted(rtl_paths.items()):
        ok(f"RTL: {macro} at {path}")
    if words:
        capacity = {m: MACROS[m][0] for m in found}
        if any(words > c for c in capacity.values()):
            fail(f"RAM_WORDS = {words}, but a macro holds only {min(capacity.values())} words")
        bits = sum(MACROS[m][1] * len(ps) for m, ps in found.items())
        if bits != 32:
            warn(f"the macros give {bits} bits per address; a 32-bit word needs exactly 32 "
                 "(one 512x32, or two 512x16)")
    if "hw/pd/sram_bb.sv" not in listed:
        fail("info.yaml must list hw/pd/sram_bb.sv (the macros' black boxes for synthesis)")

    for path, macro in sorted(rtl_paths.items()):
        if path not in cfg_paths:
            fail(f"config.json MACROS has no instance {path!r} (the RTL's path to a {macro})")
        elif cfg_paths[path] != macro:
            fail(f"config.json lists {path!r} under {cfg_paths[path]}, but the RTL has a {macro}")
    for path in sorted(set(cfg_paths) - set(rtl_paths)):
        fail(f"config.json MACROS has {path!r}, which is not a macro instance in the RTL "
             "(check the instance names from tt_um_sharc_rv32u down)")
    for macro in cfg_macros:
        if macro not in MACROS:
            fail(f"config.json MACROS has {macro}, which RV32u does not use")
        elif not cfg_macros[macro].get("lef") or not cfg_macros[macro].get("gds"):
            fail(f"config.json MACROS {macro} needs its gds and lef views")

    conns = [c.split() for c in config.get("PDN_MACRO_CONNECTIONS", [])]
    for path in sorted(rtl_paths):
        for supply in SUPPLIES:
            if not any(c[0] == path and supply in c for c in conns):
                fail(f"PDN_MACRO_CONNECTIONS has no '{path} VPWR VGND {supply} VSS!'")
    steps = config.get("meta", {}).get("substituting_steps", {})
    if "Project.ExtendPowerStripes" not in steps.values():
        fail("config.json meta.substituting_steps needs the Project.ExtendPowerStripes step "
             "(librelane_plugin_sram_pdn.py)")
    if not str(config.get("PDN_CFG", "")).endswith("pdn_cfg.tcl"):
        fail('config.json needs "PDN_CFG": "dir::hw/pd/pdn_cfg.tcl"')

    area = sum(MACROS[m][2] * len(ps) for m, ps in found.items())
    need = area + CORE_GE * UM2_PER_GE / DENSITY
    have = tiles_area(info["project"]["tiles"])
    msg = (f"estimate: macros {area / 1000:.0f}k um^2 + logic ~{CORE_GE * UM2_PER_GE / DENSITY / 1000:.0f}k um^2 "
           f"at {DENSITY:.0%} density; {info['project']['tiles']} tiles are {have / 1000:.0f}k um^2")
    (ok if need <= have else fail)(msg if need <= have else msg + ": use more tiles")
    return report()


def report() -> int:
    if errors:
        print(f"\n{len(errors)} problem(s): see spec chapter 7, 'Applying your choice'.")
        return 1
    print("\nThe RAM, its size, the cores, info.yaml and config.json agree.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
