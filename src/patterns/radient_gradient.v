/* Radient Gradient Pattern Generator
 *
 * Creates an expanding magenta-to-navy radial gradient that pulses outward
 * from the frame centre. Each 60 Hz frame receives a single next_frame tick
 * along with a fixed-point step_size that controls the amount of motion.
 */
module radient_gradient (
    input  wire       clk,
    input  wire       rst,
    input  wire       pattern_enable,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    input  wire       next_frame,
    input  wire [11:0] step_size,
    output reg  [5:0] rgb
);

    reg [9:0] frame_counter;
    reg [3:0] subframe_accum;

    wire [4:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[3:0]};
    wire [10:0] counter_sum = {1'b0, frame_counter}
                            + {{3{1'b0}}, step_size[11:4]}
                            + {{10{1'b0}}, frac_sum[4]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_counter  <= 0;
            subframe_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            frame_counter  <= counter_sum[9:0];
            subframe_accum <= frac_sum[3:0];
        end
    end

    localparam [9:0] CENTER_X = 320;
    localparam [9:0] CENTER_Y = 240;

    wire signed [10:0] sx = $signed({1'b0, x}) - $signed({1'b0, CENTER_X});
    wire signed [10:0] sy = $signed({1'b0, y}) - $signed({1'b0, CENTER_Y});

    wire [10:0] abs_dx = sx[10] ? (~sx + 1) : sx[10:0];
    wire [10:0] abs_dy = sy[10] ? (~sy + 1) : sy[10:0];

    wire [10:0] max_xy = (abs_dx > abs_dy) ? abs_dx : abs_dy;
    wire [10:0] min_xy = (abs_dx > abs_dy) ? abs_dy : abs_dx;

    wire [11:0] approx_dist = {1'b0, max_xy} + {1'b0, (min_xy >> 1)};
    wire [7:0] distance_scaled = approx_dist[9:2]; // Divide by 4 for broader range

    // Generate a triangular wave radius: expand then gently contract.
    wire [7:0] radius_phase = frame_counter[9:2]; // Slow animation
    wire [7:0] radius_cycle = (radius_phase < 120) ?
                              radius_phase :
                              (239 - radius_phase);
    wire [7:0] base_radius = 30 + radius_cycle; // 30 .. 150 pixels

    wire [7:0] core_limit = (base_radius > 15) ? (base_radius - 15) : 0;
    wire [7:0] glow_limit = base_radius + 12;
    wire [7:0] inner_limit = base_radius + 30;
    wire [7:0] outer_limit = base_radius + 50;
    wire [7:0] halo_limit = base_radius + 80;

    reg [1:0] red_level;
    reg [1:0] blue_level;
    reg [5:0] color_sel;

    always @(*) begin
        color_sel  = 6'b000000;
        red_level  = 0;
        blue_level = 0;

        if (active) begin
            // Default to a deep navy edge.
            red_level  = 0;
            blue_level = 1;

            if (distance_scaled <= core_limit) begin
                red_level  = 3;
                blue_level = 3;
            end else if (distance_scaled <= glow_limit) begin
                red_level  = 3;
                blue_level = 2;
            end else if (distance_scaled <= inner_limit) begin
                red_level  = 2;
                blue_level = 2;
            end else if (distance_scaled <= outer_limit) begin
                red_level  = 1;
                blue_level = 2;
            end else if (distance_scaled <= halo_limit) begin
                red_level  = 0;
                blue_level = 2;
            end

            color_sel = {red_level, 2'b00, blue_level};
        end
    end

    always @(*) begin
        rgb = {
            color_sel[5],
            color_sel[3],
            color_sel[1],
            color_sel[4],
            color_sel[2],
            color_sel[0]
        };
    end

    wire _unused_inputs = |{abs_dx[10], abs_dy[10]};

endmodule
