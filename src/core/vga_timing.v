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
    // H_FRONT = 16, H_SYNC = 96, H_BACK = 48
    localparam H_DISPLAY = 640;
    localparam H_TOTAL = 800;  // H_DISPLAY + H_FRONT + H_SYNC + H_BACK
    localparam H_SYNC_START = 656;  // H_DISPLAY + H_FRONT
    localparam H_SYNC_END = 752;  // H_SYNC_START + H_SYNC

    // Vertical timing parameters (in scan lines)
    // V_FRONT = 10, V_SYNC = 2, V_BACK = 33
    localparam V_DISPLAY = 480;
    localparam V_TOTAL = 525;  // V_DISPLAY + V_FRONT + V_SYNC + V_BACK
    localparam V_SYNC_START = 490;  // V_DISPLAY + V_FRONT
    localparam V_SYNC_END = 492;  // V_SYNC_START + V_SYNC

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
    assign hsync = !((x >= H_SYNC_START) && (x < H_SYNC_END));
    assign vsync = !((y >= V_SYNC_START) && (y < V_SYNC_END));

endmodule
