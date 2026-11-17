"""cocotb harness for rv32u_soc: clock, reset, program loading and the lockstep checker.

The provided tests (test_isa.py, test_c.py) run a program on the RTL and on the reference
model (src/hw/dv/model/rv32u_iss.py) side by side. Every time the core's retire port
reports an instruction (rvfi_valid), the model executes one instruction too, and every
field must match (spec 06-retire-and-trap.md). The first difference fails the test with
the PC, the disassembly and the recent history, which usually points straight at the
broken state or control signal.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

from dv.model.rv32u_iss import Retire, Rv32uIss, disassemble
from dv.programs import Program, ram_words

CLOCK_NS = 20  # 50 MHz, the timing target (spec 10)
FIELDS = ("pc", "insn", "pc_next", "rd_addr", "rd_wdata", "trap")
MEM_FIELDS = {"lw": ("mem_addr", "mem_rdata"), "sw": ("mem_addr", "mem_wstrb", "mem_wdata")}


class LockstepError(AssertionError):
    pass


async def load(dut, words: list[int]) -> None:
    """Write a program image into the RAM through rv32u_soc's simulation-only test load
    port (the memory subsystem's loader port, one word per cycle), padding the rest of the
    RAM with zeros. The port holds the CPU in reset while it is active. Going through the
    loader port, not into the RAM's storage, means this works for any RAM design (D1)."""
    n = ram_words()
    if len(words) > n:
        raise ValueError(f"the image is {len(words)} words; the RAM has {n} "
                         "(RV32U_RAM_WORDS, decision D1)")
    image = list(words) + [0] * (n - len(words))
    dut.tb_load.value = 1
    for i, w in enumerate(image):
        await FallingEdge(dut.clk)
        dut.tb_ld_we.value = 1
        dut.tb_ld_addr.value = 4 * i
        dut.tb_ld_wdata.value = w
    await FallingEdge(dut.clk)
    dut.tb_ld_we.value = 0
    dut.tb_load.value = 0


async def start(dut, words: list[int]) -> None:
    """Start the clock, hold reset, load the program, release reset. (cocotb stops a
    test's clock when the test ends, so every test starts its own.)"""
    cocotb.start_soon(Clock(dut.clk, CLOCK_NS, unit="ns").start())
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    await load(dut, words)
    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1


def _sample(dut) -> Retire:
    def v(name: str) -> int:
        value = getattr(dut, f"rvfi_{name}").value
        if not value.is_resolvable:
            raise LockstepError(
                f"rvfi_{name} = {value} has X/Z bits at a retire: a register read before it "
                "was written, an undriven signal, or a missing reset (spec 06)")
        return int(value)
    return Retire(pc=v("pc"), insn=v("insn"), pc_next=v("pc_next"), rd_addr=v("rd_addr"),
                  rd_wdata=v("rd_wdata"), mem_addr=v("mem_addr"), mem_wstrb=v("mem_wstrb"),
                  mem_wdata=v("mem_wdata"), mem_rdata=v("mem_rdata"), trap=bool(v("trap")))


def _fmt(r: Retire) -> str:
    s = f"pc=0x{r.pc:08x}  {disassemble(r.insn, r.pc):32s}"
    if r.trap:
        return s + "  TRAP"
    if r.rd_addr:
        s += f"  x{r.rd_addr}=0x{r.rd_wdata:08x}"
    if r.mem_wstrb:
        s += f"  mem[0x{r.mem_addr:x}]<=0x{r.mem_wdata:08x}"
    elif r.name == "lw":
        s += f"  mem[0x{r.mem_addr:x}]=>0x{r.mem_rdata:08x}"
    return s + f"  next=0x{r.pc_next:08x}"


@dataclass
class RunResult:
    iss: Rv32uIss
    retired: int
    cycles: int
    last: Retire


async def run_lockstep(dut, program: Program, max_cycles: int,
                       idle_limit: int = 200) -> RunResult:
    """Run `program` on the RTL and the model in lockstep until it halts (a trap or an
    instruction that jumps to itself).

    Only the sequence of retired instructions is compared: how many cycles each one
    takes, and which states the FSM passes through, are the design's own (spec 05)."""
    iss = Rv32uIss(ram_words() * 4)
    words = program.words()
    iss.load_words(words)
    await start(dut, words)
    history: deque[str] = deque(maxlen=8)
    cycle = last_retire_cycle = 0
    retired = 0
    while True:
        await FallingEdge(dut.clk)
        cycle += 1
        if cycle > max_cycles:
            raise LockstepError(f"{program.name}: no halt within {max_cycles} cycles "
                                f"({retired} instructions retired)")
        if not int(dut.rvfi_valid.value):
            if cycle - last_retire_cycle > idle_limit:
                hint = ("no instruction has ever retired: does your core fetch from address 0 "
                        "after reset, and is rvfi_valid driven? (spec 05, 06)" if retired == 0 else
                        "the core has stopped retiring: a state that never exits, or a "
                        "missed mem_ready? (raise idle_limit if your design is very slow)")
                raise LockstepError(f"{program.name}: {idle_limit} cycles without a retired "
                                    f"instruction after {retired} retired. {hint}")
            continue
        got, want = _sample(dut), iss.step()
        retired += 1
        fields = FIELDS + MEM_FIELDS.get(want.name, ())
        if want.trap:
            fields = ("pc", "trap")
        diffs = [f for f in fields if getattr(got, f) != getattr(want, f)]
        if diffs:
            raise LockstepError(
                f"{program.name}: retired instruction #{retired} differs from the reference "
                f"model in {', '.join(diffs)} (cycle {cycle})\n"
                f"  RTL:   {_fmt(got)}\n  model: {_fmt(want)}\n"
                "  previous instructions:\n    " + "\n    ".join(history or ["(none)"]))
        history.append(_fmt(got))
        last_retire_cycle = cycle
        if want.halts:
            return RunResult(iss, retired, cycle, want)


def check_expectations(program: Program, result: RunResult) -> None:
    errors = []
    last, iss = result.last, result.iss
    if program.trap_pc is not None:
        if not last.trap or last.pc != program.trap_pc:
            errors.append(f"expected a trap at pc=0x{program.trap_pc:08x}, "
                          f"got {_fmt(last)}")
    elif last.trap:
        errors.append(f"unexpected trap: {_fmt(last)}")
    for reg, value in program.regs.items():
        if iss.x[reg] != value:
            errors.append(f"x{reg} = 0x{iss.x[reg]:08x}, expected 0x{value:08x}")
    for addr, value in program.expected_words().items():
        if iss.word(addr) != value:
            errors.append(f"mem[0x{addr:x}] = 0x{iss.word(addr):08x}, expected 0x{value:08x}")
    if errors:
        raise AssertionError(f"{program.name}: " + "; ".join(errors))
