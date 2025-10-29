/* WatPixels Top-Level Module
 *
 * Implements the complete demoscene system per proposal
 */
module watpixels_top (
    input wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,  // Dedicated outputs
    input wire [7:0] uio_in,   // Bidirectional IOs (unused in this project)
    output wire [7:0] uio_out, // Bidirectional outputs
    output wire [7:0] uio_oe,  // Bidirectional enable (all inputs)
    input wire ena,            // Enable (ignore)
    input wire clk,            // 25.2 MHz pixel clock
    input wire rst_n           // Reset (active low)
);

    // Input Signal Mapping
    wire pause = ui_in[0];
    wire resume = ui_in[1];
    wire speed_1 = ui_in[2];
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
                    speed_2 ? 2 :
                    speed_1 ? 1 : 3; // Default to speed 3

    // VGA Timing Signals
    wire hsync, vsync, active;
    wire [9:0] x_pos, y_pos;

    // Convert active-low reset to active-high
    wire rst = ~rst_n;
    wire _unused_uio_in = |uio_in;

    // Pattern Output
    wire [5:0] pattern_rgb;
    wire next_frame;
    localparam [1:0] PATTERN_CHECKERBOARD = 2'd0;
    localparam [1:0] PATTERN_RADIENT      = 2'd1;
    localparam [7:0] FRAMES_PER_PATTERN   = 8'd240;
    reg  [1:0] pattern_select;
    reg  [7:0] frame_counter;

    // Overlay layers
    wire       emblem_draw;
    wire [5:0] emblem_rgb;
    wire       text_draw;
    wire [5:0] text_rgb;
    reg  [5:0] final_rgb;

    // Instantiate VGA Timing Generator
    vga_timing u_vga_timing(
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .active(active),
        .x(x_pos),
        .y(y_pos)
    );

    // Instantiate Speed Controller -> emits next_frame pulse
    speed_controller u_speed_controller(
        .clk(clk),
        .rst(rst),
        .speed({5'b0, speed}),
        .pause(pause),
        .resume(resume),
        .next_frame(next_frame)
    );

    // Alternate patterns every FRAMES_PER_PATTERN frame requests.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_counter  <= 8'd0;
            pattern_select <= PATTERN_CHECKERBOARD;
        end else if (next_frame) begin
            if (frame_counter == FRAMES_PER_PATTERN - 8'd1) begin
                frame_counter  <= 8'd0;
                pattern_select <= (pattern_select == PATTERN_CHECKERBOARD) ? PATTERN_RADIENT
                                                                          : PATTERN_CHECKERBOARD;
            end else begin
                frame_counter <= frame_counter + 8'd1;
            end
        end
    end

    // Instantiate Pattern Selector -> routes to the desired pattern module
    pattern_selector u_pattern_selector(
        .clk(clk),
        .rst(rst),
        .x(x_pos),
        .y(y_pos),
        .active(active),
        .next_frame(next_frame),
        .pattern_select(pattern_select),
        .rgb(pattern_rgb)
    );

    emblem_gen u_emblem_gen(
        .clk(clk),
        .rst(rst),
        .x(x_pos),
        .y(y_pos),
        .active(active),
        .next_frame(next_frame),
        .draw(emblem_draw),
        .rgb(emblem_rgb)
    );

    text_gen u_text_gen(
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
    assign uio_out = 8'b0; // Not used
    assign uio_oe = 8'b0; // All bidirectional pins are inputs

    // Unused Inputs
    wire _unused_ena = ena;

endmodule
