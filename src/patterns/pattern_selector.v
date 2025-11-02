// Pattern Selector for the different patterns
module pattern_selector (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire next_frame,
    input wire [1:0] pattern_select,
    output reg [5:0] rgb
);
    localparam [1:0] PATTERN_CHECKERBOARD = 0;
    localparam [1:0] PATTERN_RADIENT = 1;

    wire [5:0] checkboard_rgb;
    wire [5:0] radient_rgb;

    checkerboard_gen u_checkerboard_gen(
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .active((pattern_select == PATTERN_CHECKERBOARD) ? active : 0),
        .next_frame((pattern_select == PATTERN_CHECKERBOARD) ? next_frame : 0),
        .rgb(checkboard_rgb)
    );

    radient_gradient u_radient_gradient(
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .active((pattern_select == PATTERN_RADIENT) ? active : 0),
        .next_frame((pattern_select == PATTERN_RADIENT) ? next_frame : 0),
        .rgb(radient_rgb)
    );

    always @(*) begin
        case (pattern_select)
            PATTERN_CHECKERBOARD: rgb = checkboard_rgb;
            PATTERN_RADIENT: rgb = radient_rgb;
            default: rgb = 6'b000000;
        endcase
    end

endmodule
