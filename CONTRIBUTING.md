# Contributing

This file is for people improving the mini-project itself (the specification, the tests, the flow). If you are doing the mini-project, start at [docs/guide/getting-started.md](docs/guide/getting-started.md).

## Conventions

| Item | Convention |
|------|------------|
| Default branch | `main` (Tiny Tapeout CI also runs on `dev`) |
| Pages | kebab-case `.md`: `docs/guide/` (reading), `docs/spec/` (the specification), `docs/milestones/` (doing) |
| Adding a page | the page, a row in the course path on `docs/index.md`, a sidebar entry in `docs/_quarto.yml` and a chapter in `docs/_quarto-pdf.yml`, all in the same position |
| Requirements | numbered per chapter (`R5.1`) and written with "must"; every one is checked by a test or by the acceptance table in chapter 11 |
| Design decisions | numbered `D1`-`D8`; a callout box in the spec chapter (constraints, options, what to record), a matching section in `DESIGN.md`, and a row in chapter 1's table |
| Timing diagrams | WaveJSON in `docs/assets/wavedrom/`, rendered with `uv run --group docs scripts/render-wavedrom.py`; commit both |
| Links between pages | relative to the page they are in |
| Images | `docs/assets/img/`, linked relative to the page |

## Changing the tests or the model

- The reference model (`verif/model/rv32u_iss.py`) is the specification in code. Change it together with the chapter it implements, and add a self-test (`make model-test`).
- A new ISA test is `sw/isa/<name>.S` with an `# expect:` header; a new C program is `sw/c/<name>.c` with `// expect:`. Work the expected values out by hand, not from the RTL.
- Before committing, run the reference solution (instructors keep it in the gitignored `solution/`): `make test SOLUTION=1` for each RAM option, then `scripts/select-memory.py macro_512x32` to restore the default.

## What never goes in the repo

The reference solution, grades and anything personal. `solution/` is gitignored; keep it that way.
