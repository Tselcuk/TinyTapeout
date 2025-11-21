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

    reg [5:0] rotation_offset;  // Reduced from 8 to 6 bits
    reg [1:0] subframe_accum;

    wire [2:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[1:0]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotation_offset <= 0;
            subframe_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            rotation_offset <= rotation_offset + {3'b0, step_size[2], 1'b0} + {3'b0, frac_sum[2], 1'b0};
            subframe_accum <= frac_sum[1:0];
        end
    end

    localparam [9:0] CENTER_X = 320;
    localparam [9:0] CENTER_Y = 240;

    // Unsigned arithmetic - avoid signed operations
    wire x_lt_center = (x < CENTER_X);
    wire y_lt_center = (y < CENTER_Y);
    wire [9:0] dx = x_lt_center ? (CENTER_X - x) : (x - CENTER_X);
    wire [9:0] dy = y_lt_center ? (CENTER_Y - y) : (y - CENTER_Y);
    wire [9:0] radius = dx + dy; // Manhattan distance (10 bits sufficient for 640x480)

    // Simplified angle sector: 3 bits from signs and comparison
    wire dx_gt_dy = dx > dy;
    wire [2:0] angle_sector = {~x_lt_center, ~y_lt_center, dx_gt_dy};
    wire [5:0] rough_angle = {angle_sector, 3'b0}; // Scale to 0-56 in steps of 8

    // Apply rotation offset (reduced precision)
    wire [5:0] angle = rough_angle + rotation_offset;

    // Create spiral by subtracting radius from angle (reduced precision)
    wire [6:0] radius_scaled = {1'b0, radius[9:4]}; // Divide by 16
    // verilator lint_off UNUSEDSIGNAL
    wire [6:0] spiral_phase = {1'b0, angle} - radius_scaled;
    // verilator lint_on UNUSEDSIGNAL
    // Only upper bits [6:3] are used; lower bits [2:0] are unused but needed for correct arithmetic
    wire [2:0] arm_index = spiral_phase[6:4];
    wire in_arm = (spiral_phase[3] == 1'b0) && (arm_index < 3'd6) && (radius > 20);

    // Color lookup table for 6 arms (more predictable than XOR logic)
    wire [5:0] arm_color =
        (arm_index == 3'd0) ? 6'b010001 :  // Arm 0: Dark cyan
        (arm_index == 3'd1) ? 6'b100011 :  // Arm 1: Red-purple
        (arm_index == 3'd2) ? 6'b111010 :  // Arm 2: Yellow
        (arm_index == 3'd3) ? 6'b001110 :  // Arm 3: Green-blue
        (arm_index == 3'd4) ? 6'b011101 :  // Arm 4: Cyan-green
        6'b101111;                         // Arm 5: Magenta-white

    always @(*) begin
        rgb = active && in_arm ? arm_color : 6'b000000;
    end

endmodule
