/* VGA Timing Generator for 640×480 @ 60Hz
 *
 * Generates horizontal and vertical sync signals per VGA spec
 * Total: 800×525 pixels per frame (640 visible + 160 hblank, 480 visible + 45 vblank)
 * Pixel Clock: 25.2 MHz
 */
module vga_timing (
    input  wire clk,
    input  wire rst,
    output reg  hsync,
    output reg  vsync,
    output reg  active,      // High during visible pixel area
    output reg  [9:0] x,     // Current pixel X position (0-799)
    output reg  [9:0] y      // Current pixel Y position (0-524)
);

    // Horizontal timing parameters (in pixel clocks)
    localparam H_DISPLAY  = 640;
    localparam H_FRONT    = 16;
    localparam H_SYNC     = 96;
    localparam H_BACK     = 48;
    localparam H_TOTAL    = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800

    // Vertical timing parameters (in scan lines)
    localparam V_DISPLAY  = 480;
    localparam V_FRONT    = 10;
    localparam V_SYNC     = 2;
    localparam V_BACK     = 33;
    localparam V_TOTAL    = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525

    // State machine for horizontal counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 10'd0;
        end else begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
            end else begin
                x <= x + 1'b1;
            end
        end
    end

    // Generate hsync (active low)
    always @(*) begin
        hsync = !((x >= H_DISPLAY + H_FRONT) && (x < H_DISPLAY + H_FRONT + H_SYNC));
    end

    // Vertical counter (increments at end of each line)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y <= 10'd0;
        end else begin
            if (x == H_TOTAL - 1) begin  // At end of line
                if (y == V_TOTAL - 1) begin
                    y <= 10'd0;
                end else begin
                    y <= y + 1'b1;
                end
            end
        end
    end

    // Generate vsync (active low)
    always @(*) begin
        vsync = !((y >= V_DISPLAY + V_FRONT) && (y < V_DISPLAY + V_FRONT + V_SYNC));
    end

    // Active display area
    always @(*) begin
        active = (x < H_DISPLAY) && (y < V_DISPLAY);
    end

endmodule

