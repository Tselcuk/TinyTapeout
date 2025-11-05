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


def is_rtl_simulation(dut):
    """Check if we're running RTL simulation (has internal hierarchy) or gate-level (flattened)."""
    try:
        # Try to access internal hierarchy - if it exists, we're in RTL mode
        _ = dut.user_project.u_vga_timing
        return True
    except AttributeError:
        return False


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
    """Test VGA timing signals. Requires RTL simulation (internal signals not available in gate-level)."""
    if not is_rtl_simulation(dut):
        cocotb.log.info("Skipping test - requires RTL simulation (internal signals not available in gate-level netlist)")
        return
    
    await initialize_dut(dut)

    # Wait until the horizontal counter is at the start of a line.
    while int(dut.user_project.u_vga_timing.x.value) != 0:
        await RisingEdge(dut.clk)

    samples = []
    for _ in range(H_TOTAL):
        x_val = int(dut.user_project.u_vga_timing.x.value)
        hsync = int(dut.uo_out[0].value)
        active = int(dut.user_project.u_vga_timing.active.value)
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
        y_val = int(dut.user_project.u_vga_timing.y.value)
        x_val = int(dut.user_project.u_vga_timing.x.value)
        if y_val == V_DISPLAY + V_FRONT and x_val == 0:
            break
        await RisingEdge(dut.clk)

    # Check that vsync stays low for exactly two lines.
    for expected_line in range(V_DISPLAY + V_FRONT, V_DISPLAY + V_FRONT + V_SYNC):
        for _ in range(H_TOTAL):
            y_val = int(dut.user_project.u_vga_timing.y.value)
            vsync = int(dut.uo_out[4].value)
            assert y_val == expected_line, "Vertical counter should hold steady throughout a line"
            assert vsync == 0, "vsync should remain low during the sync pulse"
            await RisingEdge(dut.clk)

    assert int(dut.uo_out[4].value) == 1, "vsync should return high after the sync pulse"
    assert int(dut.user_project.u_vga_timing.y.value) == V_DISPLAY + V_FRONT + V_SYNC, "Vertical counter should move to back porch"


@cocotb.test()
async def test_pause_resume_freezes_animation(dut):
    """Test pause/resume functionality. Requires RTL simulation (internal signals not available in gate-level)."""
    if not is_rtl_simulation(dut):
        cocotb.log.info("Skipping test - requires RTL simulation (internal signals not available in gate-level netlist)")
        return
    
    await initialize_dut(dut)

    # Select the fastest speed and run for a few frames to get things moving.
    dut.ui_in.value = 0b1000_0000
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)

    # Get the initial animation offset.
    initial_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)

    # Pause animation and wait for a few frames.
    dut.ui_in.value = 0b1000_0001  # Keep speed 6, assert pause
    await RisingEdge(dut.clk)
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)
    
    # Check that the animation offset hasn't changed.
    paused_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)
    assert paused_offset == initial_offset, "Animation offset should not change while paused"

    # Resume animation and verify the offset starts changing again.
    dut.ui_in.value = 0b1000_0010  # Assert resume
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0b1000_0000  # Drop resume, keep speed
    
    await RisingEdge(dut.user_project.u_vga_timing.vsync)
    await RisingEdge(dut.clk) # Allow time for value to propagate

    resumed_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)
    assert resumed_offset != paused_offset, "Animation offset should change after resuming"
