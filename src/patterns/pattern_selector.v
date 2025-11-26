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
    localparam [1:0] PATTERN_SPIRAL = 2;
    localparam [9:0] FRAMES_CHECKERBOARD = 240; // 4 seconds
    localparam [9:0] FRAMES_RADIENT = 480; // 8 seconds
    localparam [9:0] FRAMES_SPIRAL = 360; // 6 seconds
    localparam [1:0] PATTERN_LAST = PATTERN_SPIRAL;

    reg [1:0] pattern_select;
    reg [9:0] frame_counter;

    wire [5:0] checkboard_rgb;
    wire [5:0] radient_rgb;
    wire [5:0] spiral_rgb;

    wire [9:0] frames_for_current_pattern = (pattern_select == PATTERN_CHECKERBOARD) ? FRAMES_CHECKERBOARD :
                                             (pattern_select == PATTERN_RADIENT) ? FRAMES_RADIENT :
                                             FRAMES_SPIRAL;

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
            vsync_q <= 1;
        end else begin
            vsync_q <= vsync;

            if (vsync_rising) begin
                if (frame_counter == frames_for_current_pattern - 1) begin
                    frame_counter <= 0;
                    pattern_select <= (pattern_select == PATTERN_LAST)
                                      ? PATTERN_CHECKERBOARD
                                      : pattern_select + 1;
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end
    end

    checkerboard_gen u_checkerboard_gen(
        .clk(clk),
        .rst(rst),
        .pattern_enable(pattern_select == PATTERN_CHECKERBOARD),
        .x(x[5:0]),
        .y_bit5(y[5]),
        .active((pattern_select == PATTERN_CHECKERBOARD) ? active : 0),
        .next_frame((pattern_select == PATTERN_CHECKERBOARD) ? animation_trigger : 0),
        .step_size(step_size),
        .rgb(checkboard_rgb)
    );

    radient_gradient u_radient_gradient(
        .clk(clk),
        .rst(rst),
        .pattern_enable(pattern_select == PATTERN_RADIENT),
        .x(x),
        .y(y),
        .active((pattern_select == PATTERN_RADIENT) ? active : 0),
        .next_frame((pattern_select == PATTERN_RADIENT) ? animation_trigger : 0),
        .step_size(step_size),
        .rgb(radient_rgb)
    );

    spiral_gen u_spiral_gen(
        .clk(clk),
        .rst(rst),
        .pattern_enable(pattern_select == PATTERN_SPIRAL),
        .x(x),
        .y(y),
        .active((pattern_select == PATTERN_SPIRAL) ? active : 0),
        .next_frame((pattern_select == PATTERN_SPIRAL) ? animation_trigger : 0),
        .step_size(step_size),
        .rgb(spiral_rgb)
    );

    always @(*) begin
        case (pattern_select)
            PATTERN_CHECKERBOARD: rgb = checkboard_rgb;
            PATTERN_RADIENT: rgb = radient_rgb;
            PATTERN_SPIRAL: rgb = spiral_rgb;
            default: rgb = 6'b000000;
        endcase
    end

endmodule
