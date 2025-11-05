module tt_um_watpixels (
    input wire [7:0] ui_in,   // Dedicated inputs
    output wire [7:0] uo_out, // Dedicated outputs
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [7:0] uio_in,  // IOs: Input path
    /* verilator lint_on UNUSEDSIGNAL */
    output wire [7:0] uio_out,// IOs: Output path
    output wire [7:0] uio_oe, // IOs: Enable path (active high: 0=input, 1=output)
    /* verilator lint_off UNUSEDSIGNAL */
    input wire ena,           // always 1 when the design is powered, so you can ignore it
    /* verilator lint_on UNUSEDSIGNAL */
    input wire clk,           // clock
    input wire rst_n          // reset_n - low to reset
);

  // Input Signal Mapping
  wire pause = ui_in[0];
  wire resume = ui_in[1];
  /* verilator lint_off UNUSEDSIGNAL */
  wire speed_1 = ui_in[2]; // Default speed, not explicitly checked
  /* verilator lint_on UNUSEDSIGNAL */
  wire speed_2 = ui_in[3];
  wire speed_3 = ui_in[4];
  wire speed_4 = ui_in[5];
  wire speed_5 = ui_in[6];
  wire speed_6 = ui_in[7];

  // Convert speed inputs to a single speed value
  wire [2:0] speed;
  assign speed = speed_6 ? 6 :
                 speed_5 ? 5 :
                 speed_4 ? 4 :
                 speed_3 ? 3 :
                 speed_2 ? 2 : 1; // Default to speed 1 (speed_1 is ui_in[2])

  // VGA Timing Signals
  wire hsync;
  wire vsync;
  wire active;
  wire frame_start;
  wire [9:0] x_pos;
  wire [9:0] y_pos;

  // Convert active-low reset to active-high
  wire rst = ~rst_n;

  // Pattern Output
  wire [5:0] pattern_rgb;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [1:0] pattern_select_unused; // Dummy wire for unused output
  /* verilator lint_on UNUSEDSIGNAL */
  wire next_frame;
  wire [11:0] step_size;

  // Overlay layers
  wire emblem_draw;
  wire [5:0] emblem_rgb;
  wire text_draw;
  wire [5:0] text_rgb;
  reg [5:0] final_rgb;

  // Instantiate VGA Timing Generator
  vga_timing u_vga_timing (
      .clk(clk),
      .rst(rst),
      .hsync(hsync),
      .vsync(vsync),
      .active(active),
      .frame_start(frame_start),
      .x(x_pos),
      .y(y_pos)
  );

  // Instantiate Speed Controller -> emits next_frame pulse
  speed_controller u_speed_controller (
      .clk(clk),
      .rst(rst),
      .speed(speed),
      .pause(pause),
      .resume(resume),
      .frame_start(frame_start),
      .next_frame(next_frame),
      .step_size(step_size)
  );

  // Instantiate Pattern Selector -> routes to the desired pattern module
  pattern_selector u_pattern_selector (
      .clk(clk),
      .rst(rst),
      .x(x_pos),
      .y(y_pos),
      .active(active),
      .vsync(vsync),
      .next_frame(next_frame),
      .step_size(step_size),
      .pattern_select(pattern_select_unused),
      .rgb(pattern_rgb)
  );

  // Overlay layers
  emblem_gen u_emblem_gen (
      .x(x_pos),
      .y(y_pos),
      .active(active),
      .draw(emblem_draw),
      .rgb(emblem_rgb)
  );

  text_gen u_text_gen (
      .clk(clk),
      .rst(rst),
      .x(x_pos),
      .y(y_pos),
      .active(active),
      .next_frame(next_frame),
      .draw(text_draw),
      .rgb(text_rgb)
  );

  always @(*) begin
    final_rgb = pattern_rgb;
    // Overlay rendering
    if (emblem_draw) begin
      final_rgb = emblem_rgb;
    end
    if (text_draw) begin
      final_rgb = text_rgb;
    end
  end

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
  assign uio_oe = 0; // All bidirectional pins are inputs

endmodule