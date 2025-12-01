## How it works

WATpixels generates a VGA display output at 640×480 resolution with 60Hz refresh rate. The design features three animated patterns that automatically cycle:
- **Checkerboard** (4 seconds): Animated checkerboard pattern
- **Gradient** (8 seconds): Radial gradient pattern
- **Spiral** (6 seconds): Animated spiral pattern

Two overlays are rendered on top of the patterns:
- Waterloo Engineering emblem
- "Waterloo" text overlay

The design uses 2-bit color depth per channel (6-bit RGB total), providing 64 different colors.

## Design Architecture

### System Overview

The design is organized into several key modules:

1. **VGA Timing Generator** (`vga_timing.v`): Generates standard VGA timing signals and pixel coordinates
2. **Speed Controller** (`speed_controller.v`): Manages animation speed and pause/resume functionality
3. **Pattern Selector** (`pattern_selector.v`): Cycles through three background patterns with automatic timing
4. **Pattern Generators**: Three independent pattern modules (checkerboard, gradient, spiral)
5. **Overlay Generators**: Emblem and text rendering modules
6. **Top Module** (`tt_um_watpixels.v`): Integrates all components and handles output signal mapping

### VGA Timing Generation

The `vga_timing` module implements standard VGA 640×480@60Hz timing:
- **Horizontal timing**: 800 pixel clocks per line (640 visible + 160 blanking)
  - Front porch: 16 clocks
  - Sync pulse: 96 clocks (active low)
  - Back porch: 48 clocks
- **Vertical timing**: 525 scan lines per frame (480 visible + 45 blanking)
  - Front porch: 10 lines
  - Sync pulse: 2 lines (active low)
  - Back porch: 33 lines

The module maintains pixel position counters (`x`, `y`) and generates `hsync`, `vsync`, and `active` signals. The `active` signal indicates when pixel data should be generated (during the visible region).

### Speed Control and Animation

The `speed_controller` module processes user inputs:
- **Speed Selection**: `ui_in[2-7]` are processed by a priority encoder to select one of 6 speed levels (1-6)
- **Pause/Resume**: `ui_in[0]` pauses animation, `ui_in[1]` resumes
- **Step Size**: Outputs a 3-bit `step_size` value (1-6) that controls animation rate
- **Paused State**: Maintains a paused flag that prevents pattern updates

Animation advances are synchronized to VGA frame boundaries using `vsync` rising edge detection, ensuring smooth frame-by-frame updates.

### Pattern Generation

#### Pattern Selector

The `pattern_selector` module automatically cycles through three patterns:
- **Checkerboard**: 240 frames (4 seconds at 60 FPS)
- **Gradient**: 480 frames (8 seconds)
- **Spiral**: 360 frames (6 seconds)

Pattern switching occurs at VGA frame boundaries (detected via `vsync` rising edge) and only when not paused. Each pattern module receives:
- Current pixel coordinates (`x`, `y`)
- `active` signal (only generates output during visible region)
- `next_frame` trigger (synchronized to VGA frame timing)
- `step_size` for speed control
- `pattern_enable` to activate/deactivate the pattern

#### Checkerboard Pattern

The `checkerboard_gen` module creates an animated checkerboard:
- Uses only the lower 6 bits of X coordinate and bit 5 of Y for efficiency
- Maintains a `frame_offset` that advances by `step_size` each frame
- Implements fixed-point arithmetic (Q1.2 format) for smooth sub-pixel movement
- XORs shifted X coordinate with Y bit 5 to create alternating tiles
- Renders in red (`6'b100100`) on black background

#### Radial Gradient Pattern

The `radient_gradient` module generates a radial color gradient:
- Calculates distance from screen center (320, 240)
- Uses Manhattan distance (`dx + dy`) for hardware efficiency
- Maps distance to color gradient through lookup tables
- Creates smooth color transitions from center to edges

#### Spiral Pattern

The `spiral_gen` module renders a rotating 6-arm spiral:
- Divides screen into 8 angle sectors using coordinate comparisons
- Calculates angle using sector and rotation offset
- Computes spiral phase by subtracting scaled radius from angle
- Renders 6 colored arms with distinct colors (dark cyan, red-purple, yellow, green-blue, cyan-green, magenta-white)
- Rotation speed controlled by `step_size` with fixed-point accumulation
- Arms fade out near the center (radius > 20 pixels)

### Emblem Generation

The `emblem_gen` module renders the Waterloo Engineering emblem, consisting of three components:

#### Shield Background

The shield is drawn using a procedural function `shield_width()` that defines the horizontal width at each vertical position:
- Shield shape is defined by a lookup table mapping Y position to half-width
- Creates a traditional heraldic shield shape (wider at top, tapering to a point at bottom)
- Rendered in gold (`6'b110110`) with a black border (`6'b000000`)
- Border thickness: 3 pixels

#### Lions

Three lions are positioned in a triangular arrangement:
- **Top-left lion**: Positioned at `(LEFT_LION_X, TOP_LION_Y)`
- **Top-right lion**: Positioned at `(RIGHT_LION_X, TOP_LION_Y)`
- **Bottom-center lion**: Positioned at `(CENTER_LION_X, BOTTOM_LION_Y)`

Each lion is 48×45 pixels, stored as bitmask ROM data:
- Lion bitmap data is stored in the `lion_row()` function as 48-bit hex values
- Each row represents one scanline of the lion image
- Data was converted from a source bitmap image (`waterloolionlowrez.png`) using a Python script
- The script quantized RGB values to 2 bits per channel and extracted pixel data
- Lions are rendered in red (`6'b100100`)

The module checks if the current pixel falls within any lion's bounding box, then looks up the corresponding bit from the ROM to determine if the pixel should be drawn.

#### Chevron

A white chevron is overlaid at the top of the emblem:
- Original bitmap: 85×100 pixels
- Scaled 2× for display: 170×200 pixels
- Positioned at the top center of the emblem
- Chevron bitmap data stored in `chevron_row()` function as 96-bit hex values
- Only rows 37-76 of the original bitmap contain chevron data (zero padding removed)
- Data was converted from `chevron.bmp` using a black/white threshold conversion
- Rendered in white (`6'b111111`)

The chevron uses 2× pixel scaling: display coordinates are divided by 2 to index into the original bitmap data. Bit indexing accounts for the left-to-right bit ordering (bit 95 = leftmost pixel).

#### Color Priority

The emblem uses a layered rendering approach with priority:
1. **Chevron** (highest priority): White pixels
2. **Lions**: Red pixels
3. **Shield border**: Black pixels
4. **Shield background**: Gold pixels (lowest priority)

### Text Overlay

The `waterloo_text_gen` module renders "WATERLOO" text:
- Positioned below the emblem at Y=325
- Character size: 10×14 pixels
- Character spacing: 2 pixels
- Centered horizontally on screen
- Each character stored as a 5×7 bitmap in a lookup function
- Rendered in white (`6'b111111`)

### Bitmap-to-Hardware Conversion

The design includes Python scripts for converting bitmap images to Verilog ROM data:

1. **`bitmap_to_bw_csv.py`**: Converts bitmap images to CSV with black/white pixel values
   - Converts image to grayscale
   - Applies threshold (default 128) to create binary image
   - Outputs CSV with x, y, value (0=black, 1=white)

2. **`csv_to_chevron.py`**: Converts chevron CSV to Verilog case statements
   - Reads CSV and organizes pixels by row
   - Generates bitmasks for each row (1=white, 0=black)
   - Pads to 96 bits and formats as hex values for Verilog

3. **Lion conversion**: Similar process was used to convert the lion bitmap
   - Quantized RGB to 2 bits per channel
   - Extracted 48×45 pixel region
   - Generated 48-bit hex values for each row

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

Run `visualize/viz.py` to visualize the output. Adjust `visualize/harness.cpp` to change the number of frames (FRAMES) or select animation speed mode (MODE: 1-6). For hardware testing, connect to a VGA display (hsync, vsync, and RGB signals). Use `ui_in[0]` to pause, `ui_in[1]` to resume, and `ui_in[2-7]` for speed control (higher = faster).

## External hardware

VGA display (640×480, 60Hz compatible)
