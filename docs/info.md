## Project Overview

**WATpixels** is a TinyTapeout project that generates animated VGA graphics. For more information on TinyTapeout, visit (https://tinytapeout.com/). This project demonstrates a complete VGA video generator that outputs animated patterns and overlays to a standard VGA display.

## How it works

WATpixels generates a VGA display output at 640×480 resolution with 60Hz refresh rate. The design features three animated patterns that automatically cycle:
- **Checkerboard** (5 seconds): Animated checkerboard pattern
- **Gradient** (5 seconds): Radial gradient pattern
- **Radial Arm** (5 seconds): Animated radial arm pattern

Two overlays are rendered on top of the patterns:
- University of Waterloo emblem
- "Waterloo Eng" text overlay

The design uses 2-bit color depth per channel (6-bit RGB total), providing 64 different colors (we only use a subset of all possible colours in our design).

## Architecture/Design Overview

The WATpixels design is organized into several key modules that work together to generate the VGA output.

The core modules include the VGA Timing Generator in vga_timing.v, which generates pixel coordinates and synchronization signals for 640x480 at 60Hz VGA timing. The design requires a 25.2 MHz pixel clock. It tracks horizontal positions from 0 to 799 and vertical positions from 0 to 524, producing an active signal during visible pixel periods.

The Speed Controller in speed_controller.v processes user input controls to determine animation state. It converts speed selection bits ui_in[2-7] into a 3-bit step_size value from 1 to 6 via priority encoding. It also controls pause/resume based on ui_in[0] and ui_in[1] inputs.

For pattern generation, the Pattern Selector in pattern_selector.v orchestrates cycling between three patterns, switching every 300 frames (5 seconds at 60Hz). It routes pixel coordinates and animation parameters to the active pattern generator. The three pattern generators are checkerboard_gen.v, radient_gradient.v, and radial_arm_gen.v.

The overlay system includes the Emblem Generator in emblem_gen.v which renders the University of Waterloo shield emblem at a fixed screen position. The Waterloo Text Generator in waterloo_text_gen.v renders the WATERLOO ENG text overlay. Both overlay systems uses bitmap lookup to draw pixel perfect images. Both overlay systems also use a transparent color key 6'b100001 to selectively render only at specific pixel positions.

The top-level module tt_um_watpixels.v blends all layers using priority-based compositing. The text overlay has highest priority when not transparent, followed by the emblem overlay when not transparent, and finally the pattern background when in the active region.

### Input Controls
- `ui_in[0]`: Pause animation
- `ui_in[1]`: Resume animation
- `ui_in[2-7]`: Speed control (6 speed settings via priority encoder - higher pins = faster)

### Output Signals
- `uo_out[0]`: hsync
- `uo_out[1]`: B0 (Blue bit 0)
- `uo_out[2]`: G0 (Green bit 0)
- `uo_out[3]`: R0 (Red bit 0)
- `uo_out[4]`: vsync
- `uo_out[5]`: B1 (Blue bit 1)
- `uo_out[6]`: G1 (Green bit 1)
- `uo_out[7]`: R1 (Red bit 1)

## Project Structure

The source code is organized in the src directory. The top-level module is tt_um_watpixels.v which serves as the TinyTapeout wrapper. The config.json file contains the OpenLane build configuration.

The core directory contains core timing and control modules. This includes vga_timing.v for the VGA timing generator at 640x480 and 60Hz, and speed_controller.v for speed control and pause/resume logic.

The patterns directory contains pattern generation related modules. The pattern_selector.v handles pattern cycling logic. The three pattern generators are checkerboard_gen.v, radient_gradient.v, and radial_arm_gen.v.

The overlay directory contains overlay graphics modules. This includes emblem_gen.v and waterloo_text_gen.v.

The test directory contains the test suite using cocotb. This includes test.py with comprehensive test cases, tb.v as the testbench wrapper, and Makefile for test build configuration.

The visualize directory contains visualization tools. This includes harness.cpp which is the Verilator simulation harness, viz.py which is the video generation script, and vga_output.mp4 which is the generated output video.

The docs directory contains documentation including this info.md file and the original project proposal.md.

## Testing

The test suite in test/test.py uses cocotb to validate the design functionality. Tests are designed for RTL simulation and will skip when run on gate-level netlists.

### Test Cases

**test_vga_timing_generates_expected_syncs**
Validates VGA timing generator produces correct hsync/vsync pulses. Verifies horizontal counter sweeps 0-799, hsync timing (96 pixels at position 656), active region (pixels 0-639), and vsync timing (2 lines at line 490).

**test_pause_resume_freezes_animation**
Verifies pause/resume controls freeze and unfreeze animation. Tests that pause stops frame_offset increments, offset stays constant while paused, and resume allows animation to continue from paused state.

**test_speed_controller_priority_and_pause**
Validates speed controller input decoding (ui_in[7:3] => step_size 1-6), priority encoding when multiple bits set, default speed of 1, and pause/resume state latching.

**test_speed_accuracy**
Validates animation rates by verifying frame_offset increments by exactly step_size/2 per frame for each speed (1-6). Tests the precise increment formula over 20 frames and handles 6-bit counter overflow.

**test_unused_io_lines**
Confirms unused bidirectional I/O pins remain tristated (uio_out = 0, uio_oe = 0) following TinyTapeout best practices.

### How to test

To run the test suite, use `cd test && make -B`.

Alternitively, use GitHub Actions by pushing your changes to Github.

### Visualization

Generate a video visualization of the VGA output:

```sh
cd visualize
python viz.py
```

This requires [Verilator](https://www.veripool.org/verilator/) and [FFmpeg](https://ffmpeg.org/). It generates `vga_output.mp4` showing the animated patterns. To customize, edit `harness.cpp`:
- `FRAMES`: Number of frames to simulate (default: 1000)
- `MODE`: Animation speed mode 1-6 (default: 2)

For hardware testing, connect to a VGA display (hsync, vsync, and RGB signals). The design requires a 25.2 MHz pixel clock. Use `ui_in[0]` to pause, `ui_in[1]` to resume, and `ui_in[2-7]` for speed control (higher = faster).

## External hardware

VGA display (640×480, 60Hz compatible)

## Authors

Tolga Selcuk and Joshua Zhang
