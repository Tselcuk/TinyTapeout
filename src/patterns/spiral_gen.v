// Rotating spiral pattern with 6 colored arms
module spiral_gen (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire next_frame,
    input wire [2:0] step_size,
    output wire [5:0] rgb
);

    reg [5:0] rotation_offset;
    reg [1:0] subframe_accum;

    wire [2:0] frac_sum = {1'b0, subframe_accum} + {1'b0, step_size[1:0]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin // Reset the rotation offset and subframe accumulator
            rotation_offset <= 0;
            subframe_accum <= 0;
        end else if (next_frame) begin
            rotation_offset <= rotation_offset + {3'b0, step_size[2], 1'b0} + {3'b0, frac_sum[2], 1'b0};
            subframe_accum <= frac_sum[1:0];
        end
    end

    wire [9:0] dx = (x < 320) ? (320 - x) : (x - 320); // Gets absolute distance from center of screen
    wire [9:0] dy = (y < 240) ? (240 - y) : (y - 240); // Gets absolute distance from center of screen
    wire [9:0] radius = dx + dy;

    // This will create 8 angle sectors
    wire [2:0] angle_sector = {(x >= 320), (y >= 240), (dx > dy)};
    wire [5:0] rough_angle = angle_sector << 3;

    // Apply rotation offset
    wire [5:0] angle = rough_angle + rotation_offset;

    // Create spiral by subtracting radius from angle
    wire [6:0] radius_scaled = {1'b0, radius[9:4]};
    // verilator lint_off UNUSEDSIGNAL
    wire [6:0] spiral_phase = {1'b0, angle} - radius_scaled;
    // verilator lint_on UNUSEDSIGNAL
    wire in_arm = (spiral_phase[3] == 0) && (spiral_phase[6:4] < 6) && (radius > 20);

    // Color lookup table for 6 arms
    wire [5:0] arm_color =
        (spiral_phase[6:4] == 0) ? 6'b010001 :  // Arm 0: Dark cyan
        (spiral_phase[6:4] == 1) ? 6'b100011 :  // Arm 1: Red-purple
        (spiral_phase[6:4] == 2) ? 6'b111010 :  // Arm 2: Yellow
        (spiral_phase[6:4] == 3) ? 6'b001110 :  // Arm 3: Green-blue
        (spiral_phase[6:4] == 4) ? 6'b011101 :  // Arm 4: Cyan-green
        6'b101111;                              // Arm 5: Magenta-white

    assign rgb = in_arm ? arm_color : 6'b000000;

endmodule
