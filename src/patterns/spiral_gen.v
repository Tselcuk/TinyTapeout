// Rotating spiral pattern with 6 colored arms
module spiral_gen (
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

    reg [7:0] rotation_offset;
    reg [1:0] subframe_accum;

    wire [2:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[1:0]};
    wire [7:0] offset_sum = rotation_offset + {5'b0, step_size[2], 1'b0} + {5'b0, frac_sum[2], 1'b0};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotation_offset <= 0;
            subframe_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            rotation_offset <= offset_sum;
            subframe_accum <= frac_sum[1:0];
        end
    end

    localparam [9:0] CENTER_X = 320;
    localparam [9:0] CENTER_Y = 240;

    wire signed [10:0] sx = $signed({1'b0, x}) - $signed({1'b0, CENTER_X});
    wire signed [10:0] sy = $signed({1'b0, y}) - $signed({1'b0, CENTER_Y});

    wire [10:0] abs_sx = sx[10] ? -sx : sx;
    wire [10:0] abs_sy = sy[10] ? -sy : sy;
    wire [11:0] radius = abs_sx + abs_sy; // Manhattan distance

    // Simple angle approximation using quadrant and comparison
    // Quadrant (2 bits from signs) + comparison bit gives us rough 8-sector angle
    wire [2:0] angle_sector = {~sx[10], ~sy[10], abs_sx > abs_sy};
    wire [7:0] rough_angle = {angle_sector, 5'b0}; // Scale sector (0-7) to 0-224 in steps of 32

    // Apply rotation offset
    wire [7:0] angle = rough_angle + rotation_offset;

    // Create spiral by subtracting radius from angle
    wire [8:0] spiral_phase = {1'b0, angle} - radius[9:2];

    // Divide into 6 arms using upper bits
    wire [2:0] arm_index = spiral_phase[8:6];
    wire in_arm = (spiral_phase[5] == 1'b0) && (arm_index < 6) && (radius > 20);

    // Generate color directly from arm index bits
    // arm_index (0-5): R=bit0, G=bit1, B=bit2 (inverted pattern for variety)
    wire [5:0] arm_color = {
        arm_index[0] | arm_index[1],  // R high bit
        arm_index[1] | arm_index[2],  // G high bit
        ~arm_index[0] | arm_index[2], // B high bit
        arm_index[0],                  // R low bit
        arm_index[1],                  // G low bit
        ~arm_index[0] | ~arm_index[1]  // B low bit
    };

    always @(*) begin
        if (active && in_arm) begin
            rgb = arm_color;
        end else if (active) begin
            rgb = 6'b000000;
        end else begin
            rgb = 6'b000000;
        end
    end

endmodule
