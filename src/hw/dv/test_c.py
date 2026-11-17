"""C program tests (spec 09-verification.md): every program in src/sw/c/ (compiled, legalized
and checked by src/sw/Makefile) runs on the RTL in lockstep with the reference model to its
final halt, then its `expect:` results are read from RAM.

    make c                # or: fusesoc run --target=c sharc:rv32u:tb
"""

import cocotb

from dv.harness import check_expectations, run_lockstep
from dv.programs import program_enum, programs

C = {p.name: p for p in programs("c")}


@cocotb.test()
@cocotb.parametrize(program=list(program_enum("c")))
async def c_program(dut, program) -> None:
    name = program.name
    program = C[name]
    result = await run_lockstep(dut, program, max_cycles=200_000)
    check_expectations(program, result)
    cpi = result.cycles / result.retired
    dut._log.info(f"{name}: {result.retired} instructions in {result.cycles} cycles "
                  f"(CPI {cpi:.2f})")
