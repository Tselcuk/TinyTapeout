// Checkerboard pattern; advances with a fixed-point step provided by speed_controller.
module checkerboard_gen (
    input wire clk,
    input wire rst,
    input wire pattern_enable,
    input wire [9:0] x,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [9:0] y,
    /* verilator lint_on UNUSEDSIGNAL */
    input wire active,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);

    reg [7:0] frame_offset;
    reg [1:0] subpixel_accum;

    wire [2:0] frac_sum = {1'b0, subpixel_accum} + {1'b0, step_size[1:0]};
    wire [7:0] offset_sum = frame_offset
                          + {{7{1'b0}}, step_size[2]}
                          + {{7{1'b0}}, frac_sum[2]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_offset   <= 0;
            subpixel_accum <= 0;
        end else if (pattern_enable && next_frame) begin
            frame_offset   <= offset_sum;
            subpixel_accum <= frac_sum[1:0];
        end
    end

    /* verilator lint_off UNUSEDSIGNAL */
    wire [9:0] shifted_x = x + {frame_offset, 1'b0}; // This shifts the x coordinate by the frame offset and is what creates the movement of the pattern
    /* verilator lint_on UNUSEDSIGNAL */
    wire tile_select = shifted_x[5] ^ y[5]; // This is the part that actually creates the checkerboard pattern

    always @(*) begin
        rgb = (active && tile_select) ? 6'b100100 : 6'b000000;
    end

endmodule
