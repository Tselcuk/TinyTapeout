/* Pattern Selector
 *
 * Routes the common pattern generator interface to one of the available
 * pattern implementations. Additional patterns can be wired in alongside the
 * checkerboard generator as they are developed.
 */
module pattern_selector (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    input  wire       next_frame,
    input  wire [1:0] pattern_select,
    output reg  [5:0] rgb
);

    localparam [1:0] PATTERN_CHECKERBOARD = 2'd0;
    localparam [1:0] PATTERN_RADIENT      = 2'd1;

    wire        sel_checkboard = (pattern_select == PATTERN_CHECKERBOARD);
    wire        sel_radient    = (pattern_select == PATTERN_RADIENT);

    wire        next_frame_checkboard = sel_checkboard ? next_frame : 1'b0;
    wire        next_frame_radient    = sel_radient    ? next_frame : 1'b0;
    wire        active_checkboard     = sel_checkboard ? active     : 1'b0;
    wire        active_radient        = sel_radient    ? active     : 1'b0;

    wire [5:0] checkboard_rgb;
    wire [5:0] radient_rgb;

    checkerboard_gen u_checkerboard_gen(
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .active(active_checkboard),
        .next_frame(next_frame_checkboard),
        .rgb(checkboard_rgb)
    );

    radient_gradient u_radient_gradient(
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .active(active_radient),
        .next_frame(next_frame_radient),
        .rgb(radient_rgb)
    );

    always @(*) begin
        case (pattern_select)
            PATTERN_CHECKERBOARD: rgb = checkboard_rgb;
            PATTERN_RADIENT:      rgb = radient_rgb;
            default:              rgb = 6'b000000;
        endcase
    end

endmodule
