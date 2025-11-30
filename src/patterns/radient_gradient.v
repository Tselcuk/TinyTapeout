module radient_gradient (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    reg [9:0] frame_counter;
    reg [1:0] subframe_accum;

    wire [2:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[1:0]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_counter <= 0;
            subframe_accum <= 0;
        end else if (next_frame) begin
            frame_counter <= frame_counter + {9'b0, step_size[2]} + {9'b0, frac_sum[2]};
            subframe_accum <= frac_sum[1:0];
        end
    end

    // Center coordinates for 640x480 VGA screen
    // sx and sy are the signed distances from the center of the screen
    wire signed [10:0] sx = $signed({1'b0, x}) - $signed({1'b0, 10'd320}); // CENTER_X = 320
    wire signed [10:0] sy = $signed({1'b0, y}) - $signed({1'b0, 10'd240}); // CENTER_Y = 240

    // Optimized absolute value using 10 bits (max values: 320, 240 fit in 9 bits)
    wire [9:0] manhattan_distance = (sx[10] ? (~sx[9:0] + 1) : sx[9:0]) + (sy[10] ? (~sy[9:0] + 1) : sy[9:0]);

    wire [7:0] base_radius = 30 + frame_counter[7:1]; // This is what expands the pattern outwards

    // Concentric ring radii (inner to outer) - Using Manhattan distance
    wire [7:0] ring1_radius = (base_radius > 24) ? (base_radius - 24) : 0;
    wire [7:0] ring2_radius = base_radius + 24;
    wire [7:0] ring3_radius = base_radius + 48;
    wire [7:0] ring4_radius = base_radius + 72;
    wire [7:0] ring5_radius = base_radius + 96;

    always @(*) begin
        // Default to a deep navy edge.
        rgb = 6'b000001; // NAVY_EDGE

        if (manhattan_distance <= {2'b0, ring1_radius}) begin
            rgb = 6'b101101; // MAGENTA_CORE
        end else if (manhattan_distance <= {2'b0, ring2_radius}) begin
            rgb = 6'b101100; // MAGENTA_GLOW
        end else if (manhattan_distance <= {2'b0, ring3_radius}) begin
            rgb = 6'b101000; // MAGENTA_INNER_RING
        end else if (manhattan_distance <= {2'b0, ring4_radius}) begin
            rgb = 6'b001100; // MAGENTA_OUTER_RING
        end else if (manhattan_distance <= {2'b0, ring5_radius}) begin
            rgb = 6'b001000; // BLUE_HALO
        end
    end

endmodule
