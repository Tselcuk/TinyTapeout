/* Radient Gradient Pattern Generator
 *
 * Creates an expanding magenta-to-navy radial gradient that pulses outward
 * from the frame centre. The animation speed is governed externally via the
 * next_frame strobe, matching the shared WatPixels pattern interface.
 */
module radient_gradient (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    input  wire       next_frame,
    output reg  [5:0] rgb
);

    // Maintain a frame counter that steps once per serviced next_frame pulse.
    reg [9:0] frame_counter;
    reg [3:0] frame_requests;

    wire start_of_frame = (x == 10'd0) && (y == 10'd0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_counter  <= 10'd0;
            frame_requests <= 4'd0;
        end else begin
            if (next_frame && (frame_requests != 4'hF)) begin
                frame_requests <= frame_requests + 4'd1;
            end

            if (start_of_frame && (frame_requests != 4'd0)) begin
                frame_counter  <= frame_counter + 10'd1;
                frame_requests <= frame_requests - 4'd1;
            end
        end
    end

    localparam [9:0] CENTER_X = 10'd320;
    localparam [9:0] CENTER_Y = 10'd240;

    wire signed [10:0] sx = $signed({1'b0, x}) - $signed({1'b0, CENTER_X});
    wire signed [10:0] sy = $signed({1'b0, y}) - $signed({1'b0, CENTER_Y});

    wire [10:0] abs_dx = sx[10] ? (~sx + 11'd1) : sx[10:0];
    wire [10:0] abs_dy = sy[10] ? (~sy + 11'd1) : sy[10:0];

    wire [10:0] max_xy = (abs_dx > abs_dy) ? abs_dx : abs_dy;
    wire [10:0] min_xy = (abs_dx > abs_dy) ? abs_dy : abs_dx;

    wire [11:0] approx_dist = {1'b0, max_xy} + {1'b0, (min_xy >> 1)};
    wire [7:0]  distance_scaled = approx_dist[9:2]; // Divide by 4 for broader range

    // Generate a triangular wave radius: expand then gently contract.
    wire [7:0] radius_phase = frame_counter[9:2];        // Slow animation
    wire [7:0] radius_cycle = (radius_phase < 8'd120) ?
                              radius_phase :
                              (8'd239 - radius_phase);
    wire [7:0] base_radius = 8'd18 + radius_cycle;       // 18 .. 138 pixels

    wire [7:0] core_limit  = (base_radius > 8'd10) ? (base_radius - 8'd10) : 8'd0;
    wire [7:0] glow_limit  = base_radius + 8'd6;
    wire [7:0] inner_limit = base_radius + 8'd18;
    wire [7:0] outer_limit = base_radius + 8'd32;
    wire [7:0] halo_limit  = base_radius + 8'd52;

    reg [1:0] red_level;
    reg [1:0] blue_level;
    reg [5:0] color_sel;

    always @(*) begin
        color_sel  = 6'b000000;
        red_level  = 2'd0;
        blue_level = 2'd0;

        if (active) begin
            // Default to a deep navy edge.
            red_level  = 2'd0;
            blue_level = 2'd1;

            if (distance_scaled <= core_limit) begin
                red_level  = 2'd3;
                blue_level = 2'd3;
            end else if (distance_scaled <= glow_limit) begin
                red_level  = 2'd3;
                blue_level = 2'd2;
            end else if (distance_scaled <= inner_limit) begin
                red_level  = 2'd2;
                blue_level = 2'd2;
            end else if (distance_scaled <= outer_limit) begin
                red_level  = 2'd1;
                blue_level = 2'd2;
            end else if (distance_scaled <= halo_limit) begin
                red_level  = 2'd0;
                blue_level = 2'd2;
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
