module vga_timing (
    input wire clk,
    input wire rst,
    output wire hsync,
    output wire vsync,
    output wire active,
    output reg [9:0] x,
    output reg [9:0] y
);

    // Horizontal timing parameters (in pixel clocks)
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800 pixels

    // Vertical timing parameters (in scan lines)
    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525 lines

    // Pixel co-ordinate counters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else begin
            if (x == H_TOTAL - 1) begin
                x <= 0;
                if (y == V_TOTAL - 1) begin
                    y <= 0;
                end else begin
                    y <= y + 1;
                end
            end else begin
                x <= x + 1;
            end
        end
    end

    assign active = (x < H_DISPLAY) && (y < V_DISPLAY);
    assign hsync = !((x >= (H_DISPLAY + H_FRONT)) && (x < (H_DISPLAY + H_FRONT + H_SYNC)));
    assign vsync = !((y >= (V_DISPLAY + V_FRONT)) && (y < (V_DISPLAY + V_FRONT + V_SYNC)));

endmodule
