"""cocotb harness for rv32u_soc: clock, reset, RAM backdoor and the lockstep checker.

The provided tests (test_isa.py, test_c.py) run a program on the RTL and on the reference
model (verif/model/rv32u_iss.py) side by side. Every time the core's retire port
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

from verif.model.rv32u_iss import Retire, Rv32uIss, disassemble
from verif.programs import Program, mem_option, ram_words

CLOCK_NS = 20  # 50 MHz, the timing target (spec 10)
FIELDS = ("pc", "insn", "pc_next", "rd_addr", "rd_wdata", "trap")
MEM_FIELDS = {"lw": ("mem_addr", "mem_rdata"), "sw": ("mem_addr", "mem_wstrb", "mem_wdata")}


class LockstepError(AssertionError):
    pass


def _ram_arrays(dut):
    """The RAM's storage arrays for the chosen memory option (decision D1), with the bit
    slice of each 32-bit word they hold."""
    ram = dut.u_mem.u_ram
    opt = mem_option()
    if opt == "macro_512x32":
        return [(ram.u_macro.i_SRAM_1P_behavioral_bm_bist.memory, 0, 32)]
    if opt == "macro_2x512x16":
        return [(ram.u_lo.i_SRAM_1P_behavioral_bm_bist.memory, 0, 16),
                (ram.u_hi.i_SRAM_1P_behavioral_bm_bist.memory, 16, 16)]
    if opt == "flops":
        return [(ram.mem, 0, 32)]
    raise ValueError(f"unknown memory option {opt!r} in src/mem/mem_config.svh")


def preload(dut, words: list[int]) -> None:
    """Write a program image into the RAM through the simulator (backdoor), padding the
    rest with zeros. Only call it while the core is held in reset."""
    n = ram_words()
    if len(words) > n:
        raise ValueError(f"the image is {len(words)} words; the RAM has {n} (decision D1)")
    image = list(words) + [0] * (n - len(words))
    for array, lsb, width in _ram_arrays(dut):
        mask = (1 << width) - 1
        for i, w in enumerate(image):
            array[i].value = (w >> lsb) & mask


async def start(dut, words: list[int]) -> None:
    """Start the clock, hold reset, load the program, release reset. (cocotb stops a
    test's clock when the test ends, so every test starts its own.)"""
    cocotb.start_soon(Clock(dut.clk, CLOCK_NS, unit="ns").start())
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    preload(dut, words)
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
