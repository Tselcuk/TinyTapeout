// Checkerboard pattern; advances with a fixed-point step provided by speed_controller.
module checkerboard_gen (
    input wire clk,
    input wire rst,
    input wire pattern_enable,
    input wire [5:0] x,
    input wire y_bit5,
    input wire active,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    reg [7:0] frame_offset;
    reg [1:0] subpixel_accum;

    wire [2:0] frac_sum = {1'b0, subpixel_accum} + {1'b0, step_size[1:0]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_offset <= 0;
            subpixel_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            frame_offset <= frame_offset + {5'b0, step_size[2], 1'b0} + {5'b0, frac_sum[2], 1'b0};
            subpixel_accum <= frac_sum[1:0];
        end
    end

    /* verilator lint_off UNUSEDSIGNAL */
    wire [5:0] shifted_x_low = x + {frame_offset[4:0], 1'b0}; // This shifts the x coordinate by the frame offset
    /* verilator lint_on UNUSEDSIGNAL */
    wire tile_select = shifted_x_low[5] ^ y_bit5; // This is the part that actually creates the checkerboard pattern

    always @(*) begin
        rgb = (active && tile_select) ? 6'b100100 : 6'b000000;
    end

endmodule
