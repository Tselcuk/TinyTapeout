module radient_gradient (
    input wire clk,
    input wire rst,
    input wire pattern_enable,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);

    reg [9:0] frame_counter;
    reg [1:0] subframe_accum;

    wire [2:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[1:0]};
    wire [9:0] counter_sum = frame_counter
                          + {{9{1'b0}}, step_size[2]}
                          + {{8{1'b0}}, frac_sum[2]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_counter  <= 0;
            subframe_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            frame_counter  <= counter_sum;
            subframe_accum <= frac_sum[1:0];
        end
    end

    localparam [9:0] CENTER_X = 320;
    localparam [9:0] CENTER_Y = 240;

    wire signed [10:0] sx = $signed({1'b0, x}) - $signed({1'b0, CENTER_X});
    wire signed [10:0] sy = $signed({1'b0, y}) - $signed({1'b0, CENTER_Y});

    wire [10:0] abs_sx = sx[10] ? -sx : sx;
    wire [10:0] abs_sy = sy[10] ? -sy : sy;
    wire [11:0] manhattan_distance = abs_sx + abs_sy;

    wire [7:0] base_radius = 30 + frame_counter[7:1]; // This is what expands the pattern outwards

    // Concentric ring radii (inner to outer) - Adjusted for Manhattan distance
    wire [7:0] ring1_radius = (base_radius > 24) ? (base_radius - 24) : 0;
    wire [7:0] ring2_radius = base_radius + 24;
    wire [7:0] ring3_radius = base_radius + 48;
    wire [7:0] ring4_radius = base_radius + 72;
    wire [7:0] ring5_radius = base_radius + 96;

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

            if (manhattan_distance <= {4'd0, ring1_radius}) begin
                rgb = MAGENTA_CORE;
            end else if (manhattan_distance <= {4'd0, ring2_radius}) begin
                rgb = MAGENTA_GLOW;
            end else if (manhattan_distance <= {4'd0, ring3_radius}) begin
                rgb = MAGENTA_INNER_RING;
            end else if (manhattan_distance <= {4'd0, ring4_radius}) begin
                rgb = MAGENTA_OUTER_RING;
            end else if (manhattan_distance <= {4'd0, ring5_radius}) begin
                rgb = BLUE_HALO;
            end
        end
    end

endmodule
