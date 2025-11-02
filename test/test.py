# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


H_DISPLAY = 640
H_FRONT = 16
H_SYNC = 96
H_BACK = 48
H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK

V_DISPLAY = 480
V_FRONT = 10
V_SYNC = 2


async def initialize_dut(dut):
    """Hold reset, set default inputs, and start the system clock."""
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_vga_timing_generates_expected_syncs(dut):
    await initialize_dut(dut)

    # Wait until the horizontal counter is at the start of a line.
    while int(dut.u_vga_timing.x.value) != 0:
        await RisingEdge(dut.clk)

    samples = []
    for _ in range(H_TOTAL):
        x_val = int(dut.u_vga_timing.x.value)
        hsync = int(dut.uo_out[0].value)
        active = int(dut.u_vga_timing.active.value)
        samples.append((x_val, hsync, active))
        await RisingEdge(dut.clk)

    x_sequence = [entry[0] for entry in samples]
    assert x_sequence == list(range(H_TOTAL)), "Horizontal counter should sweep 0..799 each line"

    hsync_low_positions = [x for x, hs, _ in samples if hs == 0]
    assert len(hsync_low_positions) == H_SYNC, "hsync low time should be 96 pixels"
    assert hsync_low_positions[0] == H_DISPLAY + H_FRONT, "hsync should fall after active + front porch"
    assert hsync_low_positions[-1] == H_DISPLAY + H_FRONT + H_SYNC - 1, "hsync should rise after sync period"

    for x_val, _, active in samples:
        if x_val < H_DISPLAY:
            assert active == 1, "Active should be high during visible area"
        else:
            assert active == 0, "Active should drop low outside the visible area"

    # Advance to the first vertical sync line (line 490).
    while True:
        y_val = int(dut.u_vga_timing.y.value)
        x_val = int(dut.u_vga_timing.x.value)
        if y_val == V_DISPLAY + V_FRONT and x_val == 0:
            break
        await RisingEdge(dut.clk)

    # Check that vsync stays low for exactly two lines.
    for expected_line in range(V_DISPLAY + V_FRONT, V_DISPLAY + V_FRONT + V_SYNC):
        for _ in range(H_TOTAL):
            y_val = int(dut.u_vga_timing.y.value)
            vsync = int(dut.uo_out[4].value)
            assert y_val == expected_line, "Vertical counter should hold steady throughout a line"
            assert vsync == 0, "vsync should remain low during the sync pulse"
            await RisingEdge(dut.clk)

    assert int(dut.uo_out[4].value) == 1, "vsync should return high after the sync pulse"
    assert int(dut.u_vga_timing.y.value) == V_DISPLAY + V_FRONT + V_SYNC, "Vertical counter should move to back porch"


@cocotb.test()
async def test_next_frame_interval_and_pause_resume(dut):
    await initialize_dut(dut)

    # Select the fastest speed so pulses arrive quickly.
    dut.ui_in.value = 0b1000_0000
    await RisingEdge(dut.clk)

    # Wait for the first next_frame pulse after reset.
    await RisingEdge(dut.next_frame)
    await RisingEdge(dut.clk)
    assert int(dut.next_frame.value) == 0, "next_frame pulse should be one clock wide"

    # Measure the number of clocks between consecutive pulses (speed 6 -> 80_001 clocks).
    clocks_between = 0
    while True:
        await RisingEdge(dut.clk)
        clocks_between += 1
        if int(dut.next_frame.value) == 1:
            break
    assert clocks_between == 80_001, f"next_frame period should be 80_001 clocks, got {clocks_between}"

    # Pause animation and confirm pulses stop arriving.
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0b1000_0001  # Keep speed 6, assert pause
    await RisingEdge(dut.clk)

    for _ in range(40_000):
        assert int(dut.next_frame.value) == 0, "next_frame should stay low while paused"
        await RisingEdge(dut.clk)

    # Resume animation and verify pulses restart.
    dut.ui_in.value = 0b1000_0010  # Assert resume
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0b1000_0000  # Drop resume, keep speed

    resumed = False
    for _ in range(80_010):
        await RisingEdge(dut.clk)
        if int(dut.next_frame.value) == 1:
            resumed = True
            break
    assert resumed, "next_frame should resume pulsing after resume command"

    await RisingEdge(dut.clk)
    assert int(dut.next_frame.value) == 0, "next_frame pulse should still be one clock wide after resume"
