module tt_um_watpixels (
    // Rational: While we are not using all of the inputs, we still need to declare them for tinytapeout
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [7:0] ui_in,   // Dedicated inputs
    output wire [7:0] uo_out, // Dedicated outputs
    input wire [7:0] uio_in,  // IOs: Input path
    output wire [7:0] uio_out,// IOs: Output path
    output wire [7:0] uio_oe, // IOs: Enable path (active high: 0=input, 1=output)
    input wire ena,
    input wire clk,           // clock
    input wire rst_n          // reset_n - low to reset
    /* verilator lint_on UNUSEDSIGNAL */
);

  // Input Signal Mapping
  // ui_in[0]: pause
  // ui_in[1]: resume
  // ui_in[2]: speed_1 (default, not explicitly used)
  // ui_in[3]: speed_2
  // ui_in[4]: speed_3
  // ui_in[5]: speed_4
  // ui_in[6]: speed_5
  // ui_in[7]: speed_6

  // Convert speed inputs to a single speed value (priority encoder)
  wire [2:0] speed;
  assign speed = ui_in[7] ? 6 :
                 ui_in[6] ? 5 :
                 ui_in[5] ? 4 :
                 ui_in[4] ? 3 :
                 ui_in[3] ? 2 : 1;

  // VGA Timing Signals
  wire hsync;
  wire vsync;
  wire active;
  wire [9:0] x_pos;
  wire [9:0] y_pos;

  // Convert active-low reset to active-high
  wire rst = ~rst_n;

  // Pattern Output
  wire [5:0] pattern_rgb;
  wire paused;
  wire [2:0] step_size;

  // Emblem Overlay Output
  wire [5:0] emblem_rgb;

  // Waterloo Text Overlay Output
  wire [5:0] waterloo_rgb;

  wire [5:0] final_rgb;

  // Transparent color constant (technically this is a real colour, but since we never use it, we can treat it as transparent)
  localparam [5:0] COLOR_TRANSPARENT = 6'b100001;

  // Instantiate VGA Timing Generator
  vga_timing u_vga_timing (
      .clk(clk),
      .rst(rst),
      .hsync(hsync),
      .vsync(vsync),
      .active(active),
      .x(x_pos),
      .y(y_pos)
  );

  // Instantiate Speed Controller -> outputs paused state and step_size
  speed_controller u_speed_controller (
      .clk(clk),
      .rst(rst),
      .speed(speed),
      .pause(ui_in[0]),
      .resume(ui_in[1]),
      .paused(paused),
      .step_size(step_size)
  );

  // Instantiate Pattern Selector -> routes to the desired pattern module
  pattern_selector u_pattern_selector (
      .clk(clk),
      .rst(rst),
      .x(x_pos),
      .y(y_pos),
      .vsync(vsync),
      .paused(paused),
      .step_size(step_size),
      .rgb(pattern_rgb)
  );

  // Instantiate Emblem Overlay
  emblem_gen u_emblem_gen (
      .x(x_pos),
      .y(y_pos),
      .active(active),
      .rgb(emblem_rgb)
  );

  // Instantiate Waterloo Text Overlay
  waterloo_text_gen u_waterloo_text_gen (
      .x(x_pos),
      .y(y_pos),
      .active(active),
      .rgb(waterloo_rgb)
  );

  // Blend overlays with pattern, overlays take priority when not transparent
  // Gate pattern output with active (overlays handle active internally)
  wire waterloo_active = (waterloo_rgb != COLOR_TRANSPARENT);
  wire emblem_active = (emblem_rgb != COLOR_TRANSPARENT);
  assign final_rgb = waterloo_active ? waterloo_rgb :
                     (emblem_active ? emblem_rgb :
                     (active ? pattern_rgb : 6'b000000));

  // Output Signal Mapping
  assign uo_out[0] = hsync;
  assign uo_out[1] = final_rgb[0]; // B[0]
  assign uo_out[2] = final_rgb[1]; // G[0]
  assign uo_out[3] = final_rgb[2]; // R[0]
  assign uo_out[4] = vsync;
  assign uo_out[5] = final_rgb[3]; // B[1]
  assign uo_out[6] = final_rgb[4]; // G[1]
  assign uo_out[7] = final_rgb[5]; // R[1]

  // Bidirectional IOs
  assign uio_out = 0; // Not used
  assign uio_oe = 0; // Not used

endmodule
