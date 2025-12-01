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

    // Slows down the rotation speed by 4x since we divide by 4
    // Speed controller doesn't help as even in low speeds, without divison, the pattern is too fast
    wire [5:0] rotation_offset = rot_accum[7:2];

    wire [9:0] dx = (x < 320) ? (320 - x) : (x - 320);
    wire [9:0] dy = (y < 240) ? (240 - y) : (y - 240);
    // Rational: We are not using manhattan_distance[3:0], but those bits are necessary to properly compute manhattan_distance[9:4]
    /* verilator lint_off UNUSEDSIGNAL */
    wire [9:0] manhattan_distance = dx + dy; // Gets absolute manhattan distance from center of screen
    /* verilator lint_on UNUSEDSIGNAL */

    // Constructs a 6-bit angle value by using the x and y coordinates to create a 3-bit angle sector and adding the rotation offset
    wire [5:0] angle = {(x >= 320), (y >= 240), (dx > dy), 3'b0} + rotation_offset;

    // This is what creates the arms, (angle - manhattan_distance) forms the desired pattern
    // If manhattan_distance[9:4] > angle, by 2s complement, radial_phase[6] will be 1
    // Rational: We are not using radial_phase[2:0], but as that is only three bits, we can safely ignore the warning
    /* verilator lint_off UNUSEDSIGNAL */
    wire [6:0] radial_phase = {1'b0, angle} - {1'b0, manhattan_distance[9:4]};
    /* verilator lint_on UNUSEDSIGNAL */

    wire [5:0] arm_color =
        (radial_phase[5:4] == 0) ? 6'b010001 :  // Green
        (radial_phase[5:4] == 1) ? 6'b100011 :  // Red-purple
        (radial_phase[5:4] == 2) ? 6'b111010 :  // Light green
        6'b001110;                              // Blue

    assign rgb = (!radial_phase[6] && !radial_phase[3]) ? arm_color : 6'b000000;

endmodule

