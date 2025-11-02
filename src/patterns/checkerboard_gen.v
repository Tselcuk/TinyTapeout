module checkerboard_gen (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire next_frame,
    output reg [5:0] rgb
);

    // Track queued frame advances so we apply offset changes only on frame boundaries.
    reg [7:0] frame_offset;
    reg [3:0] pending_frames; // Using pending_frames prevents screen tearing

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_offset <= 0;
            pending_frames <= 0;
        end else begin
            if (next_frame && (pending_frames != 15)) begin
                pending_frames <= pending_frames + 1;
            end

            if ((x == 0) && (y == 0) && (pending_frames != 0)) begin
                frame_offset <= frame_offset + 1;
                pending_frames <= pending_frames - 1;
            end
        end
    end

    wire [9:0] shifted_x = x + (frame_offset << 2); // This shifts the x coordinate by the frame offset (multiplied by 4), we multiply by 4 else each frame would only move by 1 pixel which would be very slow
    wire tile_select = shifted_x[4] ^ y[4]; // This is the bit that actually creates the checkerboard pattern

    always @(*) begin
        rgb = (active && tile_select) ? 6'b100100 : 6'b000000; // This is the color of the checkerboard pattern, red and black
    end

endmodule
