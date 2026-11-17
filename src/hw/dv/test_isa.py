"""Per-instruction tests (spec 09-verification.md): every program in src/sw/isa/ runs on the
RTL in lockstep with the reference model, and its `expect:` results are checked. Cycle
counts are reported, not checked.

    make isa              # or: fusesoc run --target=isa sharc:rv32u:tb
"""

import cocotb

from dv.harness import check_expectations, run_lockstep
from dv.programs import program_enum, programs

ISA = {p.name: p for p in programs("isa")}


@cocotb.test()
@cocotb.parametrize(program=list(program_enum("isa")))
async def isa(dut, program) -> None:
    name = program.name
    program = ISA[name]
    result = await run_lockstep(dut, program, max_cycles=2_000)
    check_expectations(program, result)
    dut._log.info(f"{name}: {result.retired} instructions, {result.cycles} cycles")
