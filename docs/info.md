## How it works

WATpixels generates a VGA display output at 640×480 resolution with 60Hz refresh rate. The design features three animated patterns that automatically cycle:
- **Checkerboard** (4 seconds): Animated checkerboard pattern
- **Gradient** (8 seconds): Radial gradient pattern
- **Spiral** (6 seconds): Animated spiral pattern

Two overlays are rendered on top of the patterns:
- Waterloo Engineering emblem
- "Waterloo" text overlay

The design uses 2-bit color depth per channel (6-bit RGB total), providing 64 different colors.

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

## How to test

Run `visualize/viz.py` to visualize the output. Adjust `visualize/harness.cpp` to change the number of frames if needed. For hardware testing, connect to a VGA display (hsync, vsync, and RGB signals). Use `ui_in[0]` to pause, `ui_in[1]` to resume, and `ui_in[2-7]` for speed control (higher = faster).

## External hardware

VGA display (640×480, 60Hz compatible)
