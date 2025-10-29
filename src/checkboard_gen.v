/* Simple Checkerboard Pattern Generator
 *
 * Generates a red and black checkerboard that slides horizontally based on
 * the shared frame advance handshake. Designed as a lightweight alternative
 * to the original layered checkerboard implementation.
 */
module checkboard_gen (
    input  wire clk,
    input  wire rst,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire active,
    input  wire next_frame,
    output reg  [5:0] rgb
);

    // Track queued frame advances so we apply offset changes only on frame boundaries.
    reg [7:0] frame_offset;
    reg [3:0] pending_frames;

    wire start_of_frame = (x == 10'd0) && (y == 10'd0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_offset   <= 8'd0;
            pending_frames <= 4'd0;
        end else begin
            if (next_frame && (pending_frames != 4'hF)) begin
                pending_frames <= pending_frames + 4'd1;
            end

            if (start_of_frame && (pending_frames != 4'd0)) begin
                frame_offset   <= frame_offset + 8'd1;
                pending_frames <= pending_frames - 4'd1;
            end
        end
    end

    wire [9:0] shifted_x   = x + {2'b00, frame_offset};
    wire       tile_select = shifted_x[4] ^ y[4];

    always @(*) begin
        rgb = (active && tile_select) ? 6'b100100 : 6'b000000;
    end

    wire _unused = |{x[9:5], y[9:5]};

endmodule
