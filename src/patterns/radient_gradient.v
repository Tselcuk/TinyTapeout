module radient_gradient (
    input wire clk,
    input wire rst,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire next_frame,
    input wire [2:0] step_size,
    output reg [5:0] rgb
);
    reg [9:0] frame_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) frame_counter <= 0;
        else if (next_frame) frame_counter <= frame_counter + {7'b0, step_size};
    end

    wire [9:0] dx = (x < 320) ? (320 - x) : (x - 320);
    wire [9:0] dy = (y < 240) ? (240 - y) : (y - 240);
    wire [9:0] manhattan_distance = dx + dy;

    // This expands the pattern outwards by changing the base radius
    // Slow down the expansion by 8x since we divide by 8
    wire [9:0] base_radius = {3'b0, frame_counter[9:3]};

    always @(*) begin
        rgb = 6'b000001; // NAVY_EDGE

        if      (manhattan_distance <= base_radius + 1*24) rgb = 6'b101101; // MAGENTA_CORE
        else if (manhattan_distance <= base_radius + 2*24) rgb = 6'b101100; // MAGENTA_GLOW
        else if (manhattan_distance <= base_radius + 3*24) rgb = 6'b101000; // MAGENTA_INNER_RING
        else if (manhattan_distance <= base_radius + 4*24) rgb = 6'b001100; // MAGENTA_OUTER_RING
        else if (manhattan_distance <= base_radius + 5*24) rgb = 6'b001000; // BLUE_HALO
    end

endmodule
