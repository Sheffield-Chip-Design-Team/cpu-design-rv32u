# 10. Tiny Tapeout integration

RV32u is taped out as a [Tiny Tapeout](https://tinytapeout.com) project on the **IHP SG13CMOS5L** process. `src/hw/pd/tt_um_sharc_rv32u.sv` is the top level, and it must keep the standard Tiny Tapeout ports. The GitHub Actions in `.github/workflows/` run the whole Tiny Tapeout flow on every push to `main` or `dev`:

| Action | Does |
|---|---|
| `gds` | synthesises and hardens the design with LibreLane (`TinyTapeout/tt-gds-action`, the `ttihp27a` shuttle flow, PDK `ihp-sg13cmos5l`) |
| `precheck` | the Tiny Tapeout DRC and pin checks on the GDS |
| `gl_test` | `test/` on the gate-level netlist (`make GATES=yes`) |
| `viewer` | republishes the project site with the layout under `viewer/` (the navbar's **Layout viewer**: the Tiny Tapeout 3D viewer, the 2D render and the GDS) |
| `docs` | checks `docs/info.md`, the project datasheet |

## Fixed requirements

- R10.1: **Pins:** only the Tiny Tapeout ports (`ui_in`, `uo_out`, `uio_in`, `uio_out`, `uio_oe`, `clk`, `rst_n`, `ena`). Every output must be driven. `info.yaml` must describe every pin you use (D5).
- R10.2: **Clock:** the design must meet timing at **50 MHz** (`CLOCK_PERIOD` 20 ns in `src/config.json`; `clock_hz` in `info.yaml`).
- R10.3: **Tiles:** the area in `info.yaml` (`tiles`, set with the memory option: [chapter 7](07-memory-subsystem.md)) must fit. With an SRAM macro, that is 6x2.
- R10.4: **Synthesis:** the RTL must stay in the subset Yosys supports ([chapter 4](04-microarchitecture.md), R4.3-R4.7).
- R10.5: **SRAM macros:** placed and powered by `src/config.json` (your SRAM entries, [chapter 7](07-memory-subsystem.md#applying-your-choice)) and the LibreLane plugin `librelane_plugin_sram_pdn.py` (from Tiny Tapeout's SRAM example). Instance names in `MACROS` must match your RTL hierarchy, for example `u_soc.u_mem.u_ram.u_sram.u_macro` (`make mem-check` checks it).

::: {.callout-warning title="Make the core observable"}
Synthesis removes logic that no output pin depends on. With the starter's I/O stubs, nothing on the pins depends on the core, so the core and RAM would be optimized away. Only the SRAM macro survives, because it is marked `(* keep *)`. A working chip needs your loader and I/O (D2-D5).
:::

## Design decisions

::: {.callout-important title="Design decision D2: program loader"}
**Decide:** how a compiled program gets into the RAM on the chip, in `src/hw/rtl/io_ss/rv32u_loader.sv`.

**Constraints:** use only the Tiny Tapeout pins. The demo board's RP2040 (or a PC through it) is the obvious host. Write the RAM through `rv32u_mem_ss`'s loader port (one word per cycle, word aligned) while the core is held in reset (`core_rst_n` low). Release the core cleanly, and do not write while it runs. External signals must pass through a synchroniser before use.

**Options:** an SPI slave (a 64-bit frame per word: address, then data); a UART receiver (simple from a PC, slower); a parallel byte strobe on `uio` (fast, many pins).

**Record in DESIGN.md (D2):** the interface and pins, the protocol, the reset and hand-off, and how you tested it.
:::

::: {.callout-important title="Design decision D3: I/O registers and memory map"}
**Decide:** what lives in the I/O region (`addr[31] = 1`), in `src/hw/rtl/io_ss/rv32u_io.sv`.

**Constraints:** `rv32u_io` follows the [bus protocol](03-memory-bus.md) as a slave: every access must complete (`io_ready`). Word access only. The provided tests never touch the I/O region, so they are not affected.

**Options:** a GPIO output register driving `uo_out`; a status register (e.g. `trap`); a free-running cycle counter (useful for measuring CPI on the chip); a GPIO input register reading `uio_in`.

**Record in DESIGN.md (D3):** a table of address, name, read/write, bits and function, and what the other I/O addresses do.
:::

::: {.callout-important title="Design decision D4: halt and done signalling"}
**Decide:** how you, and a script on the demo board, can tell that a program has finished, and whether it trapped.

**Constraints:** the core has no "halt" instruction: programs end in a self-loop (`crt0`), and traps stop the core ([chapter 6](06-retire-and-trap.md)).

**Options:** software writes a done code to a GPIO register (D3); `trap` on a dedicated pin; a status register the host reads through the loader's interface.

**Record in DESIGN.md (D4):** how software signals done, how it shows on the board, and how a trap shows.
:::

::: {.callout-important title="Design decision D5: pinout"}
**Decide:** the function of every pin you use. Fill in `info.yaml` `pinout` and `docs/info.md`, and change the pin mapping in `src/hw/rtl/rv32u_soc.sv` if yours differs from the starter's.

**Constraints:** `ui` pins are inputs only and `uo` pins outputs only. `uio` pins are bidirectional, with `uio_oe` high to drive. `clk` and `rst_n` are fixed.

**Record in DESIGN.md (D5):** the function of each pin of `ui`, `uo` and `uio`.
:::

## Hardening and its risks

The GDS action hardens the chip on every push. Read its summary and logs for:

- **utilisation:** placement fails if the design does not fit the tiles;
- **timing:** setup and hold slack at 50 MHz;
- **the SRAM:** "macro not found" means a `MACROS` instance name does not match the RTL hierarchy; power-grid (PDN) errors mean a macro is not aligned with the stripes.

Some of this is new territory:

- The IHP SRAM power scheme (the `Project.ExtendPowerStripes` step) comes from Tiny Tapeout's `ttihp-cmos5l-sram-example`, which says it is not yet proven in silicon.
- The 512-word macro placements in [chapter 7](07-memory-subsystem.md#applying-your-choice) follow that example's single 256x16 macro recipe. Expect to adjust `location` the first time the action runs with them.

To harden locally instead, open the repository in the dev container (`.devcontainer/`, needs Docker): it installs the Tiny Tapeout tools.
