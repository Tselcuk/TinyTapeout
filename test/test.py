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


async def wait_for_pause_state(dut, expected_state, max_cycles=2048):
    """Wait until the speed controller reports the desired paused state."""
    paused_signal = dut.user_project.u_speed_controller.paused
    for _ in range(max_cycles):
        if int(paused_signal.value) == expected_state:
            return
        await RisingEdge(dut.clk)
    raise AssertionError(f"Speed controller did not reach paused state {expected_state} within {max_cycles} cycles")


def read_output_rgb(dut):
    """Return the packed RGB bits from the output bus."""
    return (
        (int(dut.uo_out[7].value) << 5)
        | (int(dut.uo_out[6].value) << 4)
        | (int(dut.uo_out[5].value) << 3)
        | (int(dut.uo_out[3].value) << 2)
        | (int(dut.uo_out[2].value) << 1)
        | int(dut.uo_out[1].value)
    )


async def wait_for_position(dut, target_x, target_y, max_cycles=H_TOTAL * V_DISPLAY * 2):
    """Advance the simulation until the VGA timing block reaches a coordinate."""
    for _ in range(max_cycles):
        if (
            int(dut.user_project.u_vga_timing.x.value) == target_x
            and int(dut.user_project.u_vga_timing.y.value) == target_y
        ):
            return
        await RisingEdge(dut.clk)
    raise AssertionError(f"Timed out waiting for coordinate ({target_x}, {target_y})")


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

    # Pause animation and wait for a few frames.
    dut.ui_in.value = 0b1000_0001  # Keep speed 6, assert pause
    await RisingEdge(dut.clk)
    await wait_for_pause_state(dut, 1)

    paused_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)
        current_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)
        assert current_offset == paused_offset, "Animation offset should remain constant while paused"

    # Resume animation and verify the offset starts changing again.
    dut.ui_in.value = 0b1000_0010  # Assert resume
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0b1000_0000  # Drop resume, keep speed
    await wait_for_pause_state(dut, 0)

    resumed_offset = paused_offset
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)
        resumed_offset = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_offset.value)
        if resumed_offset != paused_offset:
            break
    assert resumed_offset != paused_offset, "Animation offset should change after resuming"


@cocotb.test()
async def test_speed_controller_priority_and_pause(dut):
    """Validate speed selection priority, defaulting, and pause/resume toggling."""
    if not is_rtl_simulation(dut):
        cocotb.log.info("Skipping test - requires RTL simulation (internal signals not available in gate-level netlist)")
        return

    await initialize_dut(dut)

    # Highest asserted speed bit wins, defaults to 1 when none set or invalid.
    vectors = [
        (0b0000_0000, 1),
        (0b0000_1000, 2),
        (0b0001_0000, 3),
        (0b0010_0000, 4),
        (0b0100_0000, 5),
        (0b1000_0000, 6),
        (0b0101_1000, 5),  # Multiple bits asserted -> highest priority bit 6 wins
        (0b1101_1000, 6),  # Bit 7 overrides everything else
    ]

    for ui_value, expected_step in vectors:
        dut.ui_in.value = ui_value
        await RisingEdge(dut.clk)
        observed = int(dut.user_project.u_speed_controller.step_size.value)
        assert observed == expected_step, f"ui_in={ui_value:08b} produced step_size={observed}, expected {expected_step}"

    # Pause/resume latches the paused state.
    dut.ui_in.value = 0b0000_0001
    await RisingEdge(dut.clk)
    assert int(dut.user_project.u_speed_controller.paused.value) == 1, "Pause input should latch paused=1"

    dut.ui_in.value = 0b0000_0010
    await RisingEdge(dut.clk)
    assert int(dut.user_project.u_speed_controller.paused.value) == 0, "Resume input should clear paused"


@cocotb.test()
async def test_color_routing_and_overlays(dut):
    """Ensure pattern output reaches the pins and overlays take priority."""
    if not is_rtl_simulation(dut):
        cocotb.log.info("Skipping test - requires RTL simulation (internal signals not available in gate-level netlist)")
        return

    await initialize_dut(dut)

    # Pause the animation to ensure consistent pattern state regardless of test execution order
    # This prevents flaky failures when random seed changes test execution order
    dut.ui_in.value = 0b0000_0001  # Assert pause
    await RisingEdge(dut.clk)
    await wait_for_pause_state(dut, 1)

    # Wait for a complete frame to ensure we're at a stable state
    await RisingEdge(dut.user_project.u_vga_timing.vsync)
    await RisingEdge(dut.user_project.u_vga_timing.vsync)

    # Base checkerboard tiles (pattern 0) - dark tile then bright tile.
    # With frame_offset=0 (after reset and pause), the pattern should be stable
    await wait_for_position(dut, 10, 10)
    assert read_output_rgb(dut) == 0b000000, "Checkerboard dark tile should output black"

    await wait_for_position(dut, 10, 40)
    assert read_output_rgb(dut) == 0b100100, "Checkerboard light tile should output green/red mix"

    # Emblem overlay should override the pattern with gold even where the pattern is bright.
    await wait_for_position(dut, 320, 200)
    assert read_output_rgb(dut) == 0b110110, "Emblem region should output gold instead of the underlying pattern"

    # Waterloo text overlay draws below the emblem and also maps through the pins.
    await wait_for_position(dut, 249, 325)
    assert read_output_rgb(dut) == 0b110110, "Text overlay pixels should be gold and reach the output bus"


@cocotb.test()
async def test_unused_io_lines(dut):
    """Verify the bidirectional IOs stay tristated as designed."""
    await initialize_dut(dut)
    await RisingEdge(dut.clk)
    assert int(dut.uio_out.value) == 0, "uio_out should remain tied low"
    assert int(dut.uio_oe.value) == 0, "uio_oe should keep all bidirectional pins as inputs"
