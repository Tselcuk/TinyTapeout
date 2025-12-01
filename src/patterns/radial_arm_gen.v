// Originally meant to be a rotating spiral pattern, but calculating exact radius takes too many bits
// Instead, this splits the screen into 8 angle sectors, shooting out chunks of color that expand outward
module radial_arm_gen (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire next_frame,
    input wire [2:0] step_size,
    output wire [5:0] rgb
);
    reg [7:0] rot_accum;

    always @(posedge clk or posedge rst) begin
        if (rst) rot_accum <= 0;
        else if (next_frame) rot_accum <= rot_accum + {5'b0, step_size};
    end

    wire [5:0] rotation_offset = rot_accum[7:2];

    wire [9:0] dx = (x < 320) ? (320 - x) : (x - 320);
    wire [9:0] dy = (y < 240) ? (240 - y) : (y - 240);
    wire [9:0] radius = dx + dy; // Gets absolute manhattan distance from center of screen

    // Constructs a 6-bit angle value by using the x and y coordinates to create a 3-bit angle sector and adding the rotation offset
    wire [5:0] angle = {(x >= 320), (y >= 240), (dx > dy), 3'b0} + rotation_offset;

    // This is what creates the arms, (angle - radius) forms the desired pattern
    // If radius[9:4] > angle, by 2s complement, radial_phase[6] will be 1
    // Rational: We are not using radial_phase[2:0], but as that is only three bits, we can safely ignore the warning
    /* verilator lint_off UNUSEDSIGNAL */
    wire [6:0] radial_phase = {1'b0, angle} - {1'b0, radius[9:4]};
    /* verilator lint_on UNUSEDSIGNAL */

    wire [5:0] arm_color =
        (radial_phase[5:4] == 0) ? 6'b010001 :  // Arm 0: Green
        (radial_phase[5:4] == 1) ? 6'b100011 :  // Arm 1: Red-purple
        (radial_phase[5:4] == 2) ? 6'b111010 :  // Arm 2: Light green
        6'b001110;                              // Arm 3: Blue

    assign rgb = (!radial_phase[6] && !radial_phase[3]) ? arm_color : 6'b000000;

endmodule

