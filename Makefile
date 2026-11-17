# RV32u mini-project: one entry point for the whole flow (docs/guide/flow.md).
#
#   make setup         Python environment (uv) + the IHP SRAM models (sparse submodule)
#   make check-env     which tools you have, and how to get the missing ones
#   make sw            build the ISA tests and C programs (sw/build/)
#   make lint          Verilator lint of the design as Tiny Tapeout builds it
#   make isa           per-instruction tests, lockstep with the reference model
#   make c             C program tests, lockstep with the reference model
#   make test          lint + isa + c + the Tiny Tapeout smoke test
#   make tt-test       the Tiny Tapeout smoke test only (test/)
#   make model-test    self-tests of the Python reference model
#   make design-check  is every design decision in DESIGN.md filled in?
#   make site          render the web page (needs Quarto)
#   make memory OPT=macro_512x32|macro_2x512x16|flops [WORDS=n]    decision D1
#
# Options: SIM=icarus (default: verilator), WAVES=1 (Icarus: dump rv32u.fst),
#          SOLUTION=1 (instructors: use solution/).

SIM      ?= verilator
SOLUTION ?=
CORES    := --cores-root src --cores-root ip --cores-root verif $(if $(SOLUTION),--cores-root solution)
FUSESOC  := uv run fusesoc $(CORES) run --no-export
TB       := sharc:rv32u:tb
SUFFIX   := $(if $(filter icarus,$(SIM)),_icarus,)

.DEFAULT_GOAL := help
.PHONY: help setup check-env sw lint isa c test tt-test model-test design-check site memory clean

help:
	@sed -n '2,18p' $(firstword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'

setup:
	uv sync
	scripts/init-submodules.sh

check-env:
	scripts/check-env.sh

sw:
	$(MAKE) -C sw

lint:
	$(FUSESOC) --target=lint sharc:rv32u:soc

WAVES_ARG := $(if $(WAVES),--waves)

isa:
	$(FUSESOC) --target=isa$(SUFFIX) $(TB) $(WAVES_ARG)
	uv run python -m cocotb_tools.check_results build/sharc_rv32u_tb_0.1.0/isa$(SUFFIX)/results.xml

c:
	$(FUSESOC) --target=c$(SUFFIX) $(TB) $(WAVES_ARG)
	uv run python -m cocotb_tools.check_results build/sharc_rv32u_tb_0.1.0/c$(SUFFIX)/results.xml

test: lint isa c tt-test

tt-test:
	cd test && uv run $(MAKE) -B && uv run python -m cocotb_tools.check_results results.xml

model-test:
	uv run pytest

design-check:
	uv run python scripts/check_design.py

site:
	quarto render docs

memory:
	scripts/select-memory.py $(OPT) $(if $(WORDS),--words $(WORDS))

clean:
	rm -rf -- build sw/build test/sim_build test/results.xml docs/_site docs/_book
