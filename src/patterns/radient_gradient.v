module radient_gradient (
    input wire clk,
    input wire rst,
    input wire pattern_enable,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire next_frame,
    input wire [11:0] step_size,
    output reg [5:0] rgb
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

    wire [21:0] dx_sq = sx * sx;
    wire [21:0] dy_sq = sy * sy;
    wire [22:0] distance_sq = dx_sq + dy_sq;

    wire [7:0] base_radius = 30 + frame_counter[7:1]; // This is what expands the pattern outwards

    // Concentric ring radii (inner to outer)
    wire [7:0] ring1_radius = (base_radius > 24) ? (base_radius - 24) : 0;
    wire [7:0] ring2_radius = base_radius + 24;
    wire [7:0] ring3_radius = base_radius + 48;
    wire [7:0] ring4_radius = base_radius + 72;
    wire [7:0] ring5_radius = base_radius + 96;

    wire [15:0] ring1_radius_sq = ring1_radius * ring1_radius;
    wire [15:0] ring2_radius_sq = ring2_radius * ring2_radius;
    wire [15:0] ring3_radius_sq = ring3_radius * ring3_radius;
    wire [15:0] ring4_radius_sq = ring4_radius * ring4_radius;
    wire [15:0] ring5_radius_sq = ring5_radius * ring5_radius;

    // Predefined RGB values in output bit order {R[1], G[1], B[1], R[0], G[0], B[0]}
    localparam [5:0] NAVY_EDGE = 6'b000001;
    localparam [5:0] MAGENTA_CORE = 6'b101101;
    localparam [5:0] MAGENTA_GLOW = 6'b101100;
    localparam [5:0] MAGENTA_INNER_RING = 6'b101000;
    localparam [5:0] MAGENTA_OUTER_RING = 6'b001100;
    localparam [5:0] BLUE_HALO = 6'b001000;

    always @(*) begin
        rgb = 6'b000000;

        if (active) begin
            // Default to a deep navy edge.
            rgb = NAVY_EDGE;

            if (distance_sq <= {7'd0, ring1_radius_sq}) begin
                rgb = MAGENTA_CORE;
            end else if (distance_sq <= {7'd0, ring2_radius_sq}) begin
                rgb = MAGENTA_GLOW;
            end else if (distance_sq <= {7'd0, ring3_radius_sq}) begin
                rgb = MAGENTA_INNER_RING;
            end else if (distance_sq <= {7'd0, ring4_radius_sq}) begin
                rgb = MAGENTA_OUTER_RING;
            end else if (distance_sq <= {7'd0, ring5_radius_sq}) begin
                rgb = BLUE_HALO;
            end
        end
    end

endmodule
