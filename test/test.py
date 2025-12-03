# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# VGA 640x480 @ 60Hz timing constants
H_DISPLAY = 640
H_FRONT = 16
H_SYNC = 96
H_BACK = 48
H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK  # 800 pixels per line

V_DISPLAY = 480
V_FRONT = 10
V_SYNC = 2


class VGATestHelper:
    """Helper utilities for VGA controller testing."""

    def __init__(self, dut):
        self.dut = dut

    def is_rtl_simulation(self):
        """Check if running RTL simulation (True) or gate-level (False)."""
        try:
            _ = self.dut.user_project.u_vga_timing
            return True
        except AttributeError:
            return False

    async def initialize_dut(self):
        """Initialize DUT: start 25MHz clock, enable design, apply reset."""
        clock = Clock(self.dut.clk, 40, units="ns")
        cocotb.start_soon(clock.start())

        self.dut.ena.value = 1
        self.dut.ui_in.value = 0
        self.dut.uio_in.value = 0
        self.dut.rst_n.value = 0
        await ClockCycles(self.dut.clk, 5)
        self.dut.rst_n.value = 1
        await ClockCycles(self.dut.clk, 2)

    async def wait_for_pause_state(self, expected_state, max_cycles=2048):
        """Wait for speed controller paused signal to match expected_state (1=paused, 0=running)."""
        paused_signal = self.dut.user_project.u_speed_controller.paused
        for _ in range(max_cycles):
            if int(paused_signal.value) == expected_state:
                return
            await RisingEdge(self.dut.clk)
        raise AssertionError(f"Speed controller did not reach paused state {expected_state} within {max_cycles} cycles")

    def read_output_rgb(self):
        """Read 6-bit RGB from output bus (uo_out[7:5,3:1] mapped to RR_GG_BB)."""
        return (
            (int(self.dut.uo_out[7].value) << 5)
            | (int(self.dut.uo_out[6].value) << 4)
            | (int(self.dut.uo_out[5].value) << 3)
            | (int(self.dut.uo_out[3].value) << 2)
            | (int(self.dut.uo_out[2].value) << 1)
            | int(self.dut.uo_out[1].value)
        )

    async def wait_for_position(self, target_x, target_y, max_cycles=H_TOTAL * V_DISPLAY * 2):
        """Wait until VGA timing reaches target pixel coordinate (x, y)."""
        for _ in range(max_cycles):
            if (
                int(self.dut.user_project.u_vga_timing.x.value) == target_x
                and int(self.dut.user_project.u_vga_timing.y.value) == target_y
            ):
                return
            await RisingEdge(self.dut.clk)
        raise AssertionError(f"Timed out waiting for coordinate ({target_x}, {target_y})")


@cocotb.test()
async def test_vga_timing_generates_expected_syncs(dut):
    """
    Validate VGA timing generator produces correct hsync/vsync signals.
    Tests horizontal counter (0-799), hsync timing (96px @ 656), active region (0-639),
    and vsync timing (2 lines @ 490).
    """
    helper = VGATestHelper(dut)
    if not helper.is_rtl_simulation():
        cocotb.log.info("Skipping test - requires RTL simulation")
        return

    await helper.initialize_dut()

    # Test horizontal timing
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
    assert x_sequence == list(range(H_TOTAL)), "Horizontal counter should sweep 0..799"

    hsync_low_positions = [x for x, hs, _ in samples if hs == 0]
    assert len(hsync_low_positions) == H_SYNC, "hsync low time should be 96 pixels"
    assert hsync_low_positions[0] == H_DISPLAY + H_FRONT, "hsync falls at pixel 656"
    assert hsync_low_positions[-1] == H_DISPLAY + H_FRONT + H_SYNC - 1, "hsync rises at pixel 751"

    for x_val, _, active in samples:
        if x_val < H_DISPLAY:
            assert active == 1, "Active high during visible area"
        else:
            assert active == 0, "Active low outside visible area"

    # Test vertical timing
    while True:
        y_val = int(dut.user_project.u_vga_timing.y.value)
        x_val = int(dut.user_project.u_vga_timing.x.value)
        if y_val == V_DISPLAY + V_FRONT and x_val == 0:
            break
        await RisingEdge(dut.clk)

    for expected_line in range(V_DISPLAY + V_FRONT, V_DISPLAY + V_FRONT + V_SYNC):
        for _ in range(H_TOTAL):
            y_val = int(dut.user_project.u_vga_timing.y.value)
            vsync = int(dut.uo_out[4].value)
            assert y_val == expected_line, "Vertical counter holds steady"
            assert vsync == 0, "vsync low during sync pulse"
            await RisingEdge(dut.clk)

    assert int(dut.uo_out[4].value) == 1, "vsync returns high after sync"
    assert int(dut.user_project.u_vga_timing.y.value) == V_DISPLAY + V_FRONT + V_SYNC, "Counter advances to back porch"


@cocotb.test()
async def test_pause_resume_freezes_animation(dut):
    """
    Verify pause/resume controls freeze and unfreeze animation.
    Tests that pause stops frame_offset increments and resume allows them again.
    """
    helper = VGATestHelper(dut)
    if not helper.is_rtl_simulation():
        cocotb.log.info("Skipping test - requires RTL simulation")
        return

    await helper.initialize_dut()

    # Start animation at fastest speed
    dut.ui_in.value = 0b1000_0000
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)

    # Pause animation
    dut.ui_in.value = 0b1000_0001
    await RisingEdge(dut.clk)
    await helper.wait_for_pause_state(1)

    frame_accum_val = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_accum.value)
    paused_offset = (frame_accum_val >> 1) & 0x3F  # Extract bits [6:1]
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)
        frame_accum_val = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_accum.value)
        current_offset = (frame_accum_val >> 1) & 0x3F  # Extract bits [6:1]
        assert current_offset == paused_offset, "Offset should stay constant while paused"

    # Resume animation
    dut.ui_in.value = 0b1000_0010
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0b1000_0000
    await helper.wait_for_pause_state(0)

    resumed_offset = paused_offset
    for _ in range(5):
        await RisingEdge(dut.user_project.u_vga_timing.vsync)
        frame_accum_val = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_accum.value)
        resumed_offset = (frame_accum_val >> 1) & 0x3F  # Extract bits [6:1]
        if resumed_offset != paused_offset:
            break
    assert resumed_offset != paused_offset, "Offset should change after resuming"


@cocotb.test()
async def test_speed_controller_priority_and_pause(dut):
    """
    Validate speed controller input decoding and pause state management.
    Tests ui_in[7:3] => step_size 1-6, priority encoding, and pause/resume latching.
    """
    helper = VGATestHelper(dut)
    if not helper.is_rtl_simulation():
        cocotb.log.info("Skipping test - requires RTL simulation")
        return

    await helper.initialize_dut()

    # Test speed selection and priority encoding
    vectors = [
        (0b0000_0000, 1), # Default
        (0b0000_1000, 2),
        (0b0001_0000, 3),
        (0b0010_0000, 4),
        (0b0100_0000, 5),
        (0b1000_0000, 6),
        (0b0101_1000, 5),
        (0b1101_1000, 6),
    ]

    for ui_value, expected_step in vectors:
        dut.ui_in.value = ui_value
        await RisingEdge(dut.clk)
        observed = int(dut.user_project.u_speed_controller.step_size.value)
        assert observed == expected_step, f"ui_in={ui_value:08b} => step_size={observed}, expected {expected_step}"

    # Test pause latching
    dut.ui_in.value = 0b0000_0001
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.user_project.u_speed_controller.paused.value) == 1, "Pause should latch"

    # Test resume clearing pause
    dut.ui_in.value = 0b0000_0010
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.user_project.u_speed_controller.paused.value) == 0, "Resume should clear pause"


@cocotb.test()
async def test_speed_accuracy(dut):
    """
    Validate speed controller produces correct animation rates.
    Verifies frame_offset increments by exactly step_size/2 per frame for each speed (1-6).
    Handles 6-bit counter overflow.
    """
    helper = VGATestHelper(dut)
    if not helper.is_rtl_simulation():
        cocotb.log.info("Skipping test - requires RTL simulation")
        return

    await helper.initialize_dut()

    speed_configs = [
        (0b0000_0000, 1),
        (0b0000_1000, 2),
        (0b0001_0000, 3),
        (0b0010_0000, 4),
        (0b0100_0000, 5),
        (0b1000_0000, 6),
    ]

    frames_to_test = 20

    # Measure increment rate for each speed
    for ui_value, expected_step in speed_configs:
        dut.ui_in.value = ui_value
        await RisingEdge(dut.clk)

        # Allow settling time
        for _ in range(3):
            await RisingEdge(dut.user_project.u_vga_timing.vsync)

        frame_accum_val = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_accum.value)
        initial_offset = (frame_accum_val >> 1) & 0x3F  # Extract bits [6:1]

        for _ in range(frames_to_test):
            await RisingEdge(dut.user_project.u_vga_timing.vsync)

        frame_accum_val = int(dut.user_project.u_pattern_selector.u_checkerboard_gen.frame_accum.value)
        final_offset = (frame_accum_val >> 1) & 0x3F  # Extract bits [6:1]

        # Handle counter overflow (frame_offset is 6-bit)
        actual_increment = final_offset - initial_offset
        if actual_increment < 0:
            actual_increment += 64  # 6-bit counter wraps at 64

        # frame_offset increments by step_size/2 per frame (frame_accum adds step_size, then divided by 2)
        # Over frames_to_test frames: expected = step_size * frames_to_test / 2
        expected_increment = expected_step * frames_to_test // 2

        assert actual_increment == expected_increment, \
            f"Speed {expected_step}: expected {expected_increment}, got {actual_increment} over {frames_to_test} frames"
        cocotb.log.info(f"Speed {expected_step}: {actual_increment} increment")


@cocotb.test()
async def test_unused_io_lines(dut):
    """
    Verify unused bidirectional I/O pins remain tristated.
    Checks uio_out=0 and uio_oe=0 to follow TinyTapeout best practices.
    """
    helper = VGATestHelper(dut)
    await helper.initialize_dut()
    await RisingEdge(dut.clk)

    assert int(dut.uio_out.value) == 0, "uio_out should be 0"
    assert int(dut.uio_oe.value) == 0, "uio_oe should be 0"
