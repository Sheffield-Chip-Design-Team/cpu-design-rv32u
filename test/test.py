# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
"""Smoke test of the Tiny Tapeout top level (RTL and gate level).

It resets the chip and runs it, then checks that every output pin is driven to a
known value. The core itself is verified by the FuseSoC flow (`make test`, spec 09);
extend this test to exercise your loader (D2) and I/O (D3-D5) through the pins, so the
gate-level run checks them on the hardened netlist too.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # 50 MHz, the design's clock target (info.yaml clock_hz)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Run")
    await ClockCycles(dut.clk, 1000)

    # Every output must be driven: no X or Z on uo_out, uio_out or uio_oe.
    for name in ("uo_out", "uio_out", "uio_oe"):
        value = getattr(dut, name).value
        assert value.is_resolvable, f"{name} = {value} after reset and 1000 cycles"
    dut._log.info(f"uo_out = {dut.uo_out.value}, uio_oe = {dut.uio_oe.value}")
