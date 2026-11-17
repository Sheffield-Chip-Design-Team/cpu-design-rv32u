# M4: Chip integration

You'll design how the chip is loaded and observed (D2-D5), harden it with the Tiny Tapeout GDS action, and finish `DESIGN.md`.

## Before you start

- Finish [M3](m3-running-c.md).
- Read [Tiny Tapeout integration](../spec/10-tiny-tapeout.md) and [Deliverables and acceptance](../spec/11-deliverables.md).
- Push your repository to GitHub, with Actions enabled and Pages set to deploy from GitHub Actions (Settings, Pages, Source). Your site and your layout viewer are published there.

Time: about 10 hours.

## Part 1: The loader and the I/O (D2, D3, D4, D5)

1. Design the loader in `src/io/rv32u_loader.sv` (D2): its pins, its protocol, and how it holds the core in reset.
2. Design the I/O registers in `src/io/rv32u_io.sv` (D3) and how a finished program shows on the pins (D4).
3. Map the pins in `src/rv32u_soc.sv`, and describe them in `info.yaml` and `docs/info.md` (D5).
4. Run `make test`: your changes must not break the provided tests.

You should see: `make test` passes, and `make lint` is clean.

## Part 2: Test through the pins (required)

The provided tests load programs through a backdoor. Now test the real path, as the chip will be used.

1. Extend `test/test.py`: drive your loader through `ui_in`/`uio_in` to load a small program (for example a built `src/sw/build/isa/*.hex`). Then release the core and check your done signal (D4) on the outputs.
2. Run `make tt-test`.

You should see: your test loads, runs and checks a program using only the Tiny Tapeout pins.

## Part 3: Harden

1. Push to `main` (or `dev`). Watch the `gds`, `precheck`, `gl_test` and `viewer` jobs in the Actions tab.
2. Read the GDS summary: utilisation, timing at 50 MHz, and any SRAM placement or power errors ([Hardening and its risks](../spec/10-tiny-tapeout.md#hardening-and-its-risks)).
3. Fix what fails and push again.

You should see: all four jobs green, and your layout under **Layout viewer** in your site's navbar (`https://<owner>.github.io/<repo>/viewer/`).

## Finishing

You're done when every row of the [acceptance table](../spec/11-deliverables.md#acceptance) holds, and `make design-check` passes.

Questions:

1. How long does your loader take to load a 200-word program at its maximum speed?
2. What is your design's worst setup slack at 50 MHz, and which path is it on?

Submit: the repository, with the GDS action's run linked in `docs/info.md`.
