// Pattern Selector for the different patterns
module pattern_selector (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire vsync,
    input wire paused,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    localparam [1:0] PATTERN_CHECKERBOARD = 0;
    localparam [1:0] PATTERN_RADIENT = 1;
    localparam [9:0] FRAMES_CHECKERBOARD = 240;
    localparam [9:0] FRAMES_RADIENT = 480;
    localparam [1:0] PATTERN_LAST = PATTERN_RADIENT;

    reg [1:0] pattern_select;
    reg switch_pending;
    reg [9:0] frame_counter;

    wire [5:0] checkboard_rgb;
    wire [5:0] radient_rgb;

    wire checkerboard_selected = (pattern_select == PATTERN_CHECKERBOARD);
    wire radient_selected = (pattern_select == PATTERN_RADIENT);
    wire [9:0] frames_for_current_pattern = (pattern_select == PATTERN_CHECKERBOARD) ? FRAMES_CHECKERBOARD : FRAMES_RADIENT;

    // Track VGA frame advances and defer pattern switches to the next frame origin.
    // Count actual VGA frames by detecting vsync rising edge (end of vsync pulse).
    // vsync is active low, so we detect when it transitions from low to high.
    
    reg vsync_q; // Stores previous value of vsync
    wire vsync_rising = vsync && !vsync_q; // Rising edge of vsync signals next frame
    wire animation_trigger = vsync_rising && !paused;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pattern_select <= PATTERN_CHECKERBOARD;
            frame_counter  <= 0;
            switch_pending <= 0;
            vsync_q <= 1;
        end else begin
            vsync_q <= vsync;

            if (vsync_rising) begin
                if (frame_counter == frames_for_current_pattern - 1) begin
                    frame_counter <= 0;
                    switch_pending <= 1;
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end

            if (switch_pending && (x == 0) && (y == 0)) begin
                pattern_select <= (pattern_select == PATTERN_LAST)
                                  ? PATTERN_CHECKERBOARD
                                  : pattern_select + 1;
                switch_pending <= 0;
                frame_counter <= 0;
            end
        end
    end

    checkerboard_gen u_checkerboard_gen(
        .clk(clk),
        .rst(rst),
        .pattern_enable(checkerboard_selected),
        .x(x[5:0]),
        .y_bit5(y[5]),
        .active(checkerboard_selected ? active : 0),
        .next_frame(checkerboard_selected ? animation_trigger : 0),
        .step_size(step_size),
        .rgb(checkboard_rgb)
    );

    radient_gradient u_radient_gradient(
        .clk(clk),
        .rst(rst),
        .pattern_enable(radient_selected),
        .x(x),
        .y(y),
        .active(radient_selected ? active : 0),
        .next_frame(radient_selected ? animation_trigger : 0),
        .step_size(step_size),
        .rgb(radient_rgb)
    );

    always @(*) begin
        case (pattern_select)
            PATTERN_CHECKERBOARD: rgb = checkboard_rgb;
            PATTERN_RADIENT: rgb = radient_rgb;
            default: rgb = 6'b000000;
        endcase
    end

endmodule
