// Checkerboard pattern; advances with a step size provided by speed_controller.
module checkerboard_gen (
    input wire clk,
    input wire rst,
    input wire [5:0] x,
    input wire y_bit5,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    reg [6:0] frame_accum;  // Accumulator to slow down animation (divides speed by 2)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_accum <= 0;
        end else if (next_frame) begin
            frame_accum <= frame_accum + {4'b0, step_size};
        end
    end

    // Slows down the animation by 2x since we divide by 2 (ignore lowest 1 bit)
    wire [5:0] frame_offset = frame_accum[6:1];

    // Rational: We only use shifted_x_low[5] (the MSB), not shifted_x_low[4:0]. However, we need to compute
    // the full addition to correctly compute shifted_x_low[5]
    /* verilator lint_off UNUSEDSIGNAL */
    wire [5:0] shifted_x_low = x + frame_offset; // This shifts the x coordinate by the frame offset
    /* verilator lint_on UNUSEDSIGNAL */
    wire tile_select = shifted_x_low[5] ^ y_bit5; // This is the part that actually creates the checkerboard pattern

    always @(*) begin
        rgb = tile_select ? 6'b100100 : 6'b000000;
    end

endmodule
