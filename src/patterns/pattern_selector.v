// Pattern Selector for the different patterns
module pattern_selector (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire vsync,
    input wire paused,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    localparam [1:0] PATTERN_CHECKERBOARD = 0;
    localparam [1:0] PATTERN_RADIENT = 1;
    localparam [1:0] PATTERN_RADIAL_ARM = 2;

    reg [1:0] pattern_select;
    reg [8:0] frame_counter;

    wire [5:0] checkboard_rgb;
    wire [5:0] radient_rgb;
    wire [5:0] radial_arm_rgb;

    localparam [8:0] FRAMES_PER_PATTERN = 300;

    wire checkerboard_next = (pattern_select == PATTERN_CHECKERBOARD) && animation_trigger;
    wire radient_next = (pattern_select == PATTERN_RADIENT) && animation_trigger;
    wire radial_arm_next = (pattern_select == PATTERN_RADIAL_ARM) && animation_trigger;

    // Track VGA frame advances and defer pattern switches to the next frame origin.
    // Count actual VGA frames by detecting vsync rising edge (end of vsync pulse).
    // vsync is active low, so we detect when it transitions from low to high.
    
    reg vsync_q; // Stores previous value of vsync
    wire vsync_rising = vsync && !vsync_q; // Rising edge of vsync signals next frame
    wire animation_trigger = vsync_rising && !paused;

    // Detect when we wrap back to first pattern
    reg pattern_wrap_pulse;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pattern_select <= PATTERN_CHECKERBOARD;
            frame_counter <= 0;
            vsync_q <= 1;
            pattern_wrap_pulse <= 0;
        end else begin
            vsync_q <= vsync;
            pattern_wrap_pulse <= 0; // Default to 0, pulse for one cycle

            if (vsync_rising) begin
                if (frame_counter == FRAMES_PER_PATTERN - 1) begin
                    // Time to switch to next pattern
                    frame_counter <= 0;
                    if (pattern_select == 2) begin
                        pattern_select <= 0;
                        pattern_wrap_pulse <= 1; // Reset patterns when wrapping
                    end else begin
                        pattern_select <= pattern_select + 1;
                    end
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end
    end

    // Combined reset
    wire pattern_rst = rst || pattern_wrap_pulse;

    checkerboard_gen u_checkerboard_gen(
        .clk(clk),
        .rst(pattern_rst),
        .x(x[5:0]),
        .y_bit5(y[5]),
        .next_frame(checkerboard_next),
        .step_size(step_size),
        .rgb(checkboard_rgb)
    );

    radient_gradient u_radient_gradient(
        .clk(clk),
        .rst(pattern_rst),
        .x(x),
        .y(y),
        .next_frame(radient_next),
        .step_size(step_size),
        .rgb(radient_rgb)
    );

    radial_arm_gen u_radial_arm_gen(
        .clk(clk),
        .rst(pattern_rst),
        .x(x),
        .y(y),
        .next_frame(radial_arm_next),
        .step_size(step_size),
        .rgb(radial_arm_rgb)
    );

    always @(*) begin
        case (pattern_select)
            PATTERN_CHECKERBOARD: rgb = checkboard_rgb;
            PATTERN_RADIENT: rgb = radient_rgb;
            PATTERN_RADIAL_ARM: rgb = radial_arm_rgb;
            default: rgb = 6'b000000;
        endcase
    end

endmodule
