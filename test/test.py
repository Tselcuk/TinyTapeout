# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge


@cocotb.test()
async def test_counter_reset_increment_load_tristate(dut):
    dut._log.info("Start")

    # Clock: 10 us period (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Default inputs
    dut.ena.value = 1
    dut.ui_in.value = 0        # [1]=out_enable=0, [0]=parallel_load=0
    dut.uio_in.value = 0

    # Assert async active-low reset then release
    dut._log.info("Apply reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # Drive out_enable so outputs are not Z when we sample
    dut.ui_in.value = 0b0000_0010
    # After reset, counter should be 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == 0, "Counter should be 0 after reset"

    # Free-run increment for 5 cycles
    await ClockCycles(dut.clk, 5)
    assert int(dut.uo_out.value) == 5, "Counter should increment to 5"

    # Parallel load value 0xA5 on next clock edge
    dut._log.info("Parallel load 0xA5")
    # Align to falling edge, then assert load and data so they are stable before next rising edge
    await FallingEdge(dut.clk)
    dut.uio_in.value = 0xA5
    dut.ui_in.value = 0b0000_0011  # out_enable=1, parallel_load=1
    await RisingEdge(dut.clk)
    # Hold parallel_load for one full cycle to be safe
    await RisingEdge(dut.clk)
    # Deassert parallel_load, keep out_enable
    dut.ui_in.value = 0b0000_0010
    # Check on next edge to observe loaded value
    await RisingEdge(dut.clk)
    assert int(dut.uo_out.value) == 0xA5, "Counter should load 0xA5"

    # Verify it increments from loaded value
    await ClockCycles(dut.clk, 3)
    assert int(dut.uo_out.value) == ((0xA5 + 3) & 0xFF), "Counter should increment from loaded value"

    # Tri-state enable drives pad enables via uio_oe
    # Turn on out_enable (ui_in[1]) and confirm uio_oe == 0xFF
    dut.ui_in.value = 0b0000_0010
    await ClockCycles(dut.clk, 1)
    assert int(dut.uio_oe.value) == 0xFF, "uio_oe should be all 1s when out_enable=1"

    # Turn off out_enable and confirm uio_oe == 0x00
    dut.ui_in.value = 0b0000_0000
    await ClockCycles(dut.clk, 1)
    assert int(dut.uio_oe.value) == 0x00, "uio_oe should be all 0s when out_enable=0"

    # Re-enable and confirm outputs are consistent when enabled
    dut.ui_in.value = 0b0000_0010
    await ClockCycles(dut.clk, 1)
    assert int(dut.uo_out.value) == int(dut.uio_out.value), "uo_out and uio_out should match when enabled"
