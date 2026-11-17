# 7. Memory subsystem

`rv32u_mem` (`src/hw/rtl/mem_ss/rv32u_mem.sv`, provided) is the slave on the core's [memory bus](03-memory-bus.md). It decodes each address to the RAM, the I/O region, or nothing.

## Memory map

| Addresses | Region | Behaviour |
|---|---|---|
| `0x0000_0000` to `RAM_BYTES - 1` | RAM | read and write words, one wait state |
| `RAM_BYTES` to `0x7FFF_FFFF` | unmapped | completes with one wait state; reads return 0, writes are ignored |
| `0x8000_0000` to `0xFFFF_FFFF` (`addr[31] = 1`) | I/O | forwarded to `rv32u_io` on the same protocol (decision [D3](10-tiny-tapeout.md)) |

`RAM_BYTES` is 2048 (2 KiB) for both macro options, and 4 x `--words` for flip-flops (decision D1 below). Code, data and the stack all live in the RAM: the program is at address 0, and the stack grows down from `RAM_BYTES`.

## The RAM interface

Every RAM option implements the same module, `rv32u_ram`:

| Port | Meaning |
|---|---|
| `en`, `we`, `addr`, `wdata` | on a rising edge with `en`: write `wdata` to word `addr` if `we`, else read it |
| `rdata` | the word read, valid in the cycle **after** the read (synchronous read) |

![rv32u_ram: a write, then a read of the same word](../assets/img/wavedrom/ram-interface.svg){.wavedrom fig-alt="WaveDrom timing diagram: en high in cycles 1 and 2; we high in cycle 1 with addr n and wdata D (the write), we low in cycle 2 with addr n (the read); rdata shows D from cycle 3."}

`rv32u_mem` turns this into the [bus protocol](03-memory-bus.md#timing). It accepts a request in the cycle `mem_valid` is high, starts the RAM access on that edge, and raises `mem_ready` (with `mem_rdata`) in the next cycle. That one wait state is why every fetch and every `LW`/`SW` takes at least two cycles.

The **loader port** (`ld_we`, `ld_addr`, `ld_wdata`) writes one RAM word per cycle and has priority over the core. Use it only while the core is held in reset (decision [D2](10-tiny-tapeout.md)). In simulation the tests load programs through the simulator instead (a "backdoor"), so the provided tests run before you design a loader.

## The RAM options

| Option | `rv32u_ram` | Size | Area | Tiles (with the core) |
|---|---|---|---|---|
| `macro_512x32` | 1 x IHP `RM_IHPSG13_1P_512x32_c2_bm_bist` | 2 KiB | macro 416.64 x 191.34 um (79,720 um^2) | 6x2 |
| `macro_2x512x16` | 2 x IHP `RM_IHPSG13_1P_512x16_c2_bm_bist`, low and high half-words | 2 KiB | 2 x 236.80 x 191.34 um (90,619 um^2) | 6x2 |
| `flops` | a flip-flop array, `--words` 16-512 | 64-2048 B | ~7.25 GE per bit + the read multiplexer: 64 words ~20k GE, 256 words ~80k GE | 64 words: 8x2; 256 words: more than 8x4 |

For scale: the reference core is about 126,000 um^2 of standard cells (about 17k gate equivalents), measured with Yosys on the IHP sg13g2 cells. About 80% of that is the 31 x 32 flip-flop register file. A Tiny Tapeout IHP tile is 202 x 155 um (6x2 tiles: about 405,000 um^2), and placement and routing need room to spare (the flow targets 60% density).

::: {.callout-important title="Design decision D1: memory implementation"}
**Decide:** which RAM the chip has: one 512x32 macro, two 512x16 macros, or a flip-flop array of a size you choose.

**Constraints:** the RAM must hold your largest program: its code, its data and its stack. The provided C programs are up to 205 words of code and data, plus their stack (e.g. `fib` recurses about 80 words deep). The chip must fit the tiles in `info.yaml` at a density the flow can place and route. Simulation and synthesis must use the same option.

**Options:**

- `macro_512x32`: one macro, 32-bit words natively, the simplest power grid (the same recipe as Tiny Tapeout's SRAM example). The largest single block to floorplan.
- `macro_2x512x16`: two narrower macros side by side. They can be placed more flexibly, but there are two power connections and slightly more area.
- `flops`: no macro and no special power grid, so the least hardening risk. But it is very expensive per bit: only a small RAM is affordable, which limits program size.

The IHP SRAM power scheme is new in Tiny Tapeout's flow and not yet proven in silicon (see [chapter 10](10-tiny-tapeout.md)).

**Record in DESIGN.md (D1):** the option, why, its area and tiles, and the largest program it runs.
:::

Apply your choice with:

```bash
scripts/select-memory.py macro_512x32            # or macro_2x512x16, or: flops --words 128
make -C sw clean && make test
```

It rewrites every file that depends on the choice: `src/hw/rtl/mem_ss/mem_config.svh` (the RTL, the software build and the tests read it), `src/config.json` (the macros' placement and power), `info.yaml` (the source files and the tile count) and `src/rv32u.core` (the RAM fileset FuseSoC builds). For `flops` it also prints an area estimate.

## Check yourself

1. Why does the RAM interface have a one-cycle read latency even for the flip-flop option?

   <details><summary>Answer</summary>
   So every option has the same timing: the SRAM macros read synchronously (the address is registered on the clock edge), and the flip-flop array does too. Your core, its cycle counts and the tests are then the same whatever you choose in D1.
   </details>
