// Returns step_size for the pattern and paused state
// step_size varies based on the speed select and affects movements of the pattern
// Use vsync_rising && !paused as the animation trigger (vsync rising edge signals next frame)
module speed_controller (
    input wire clk,
    input wire rst,
    input wire [2:0] speed,
    input wire pause,
    input wire resume,
    output reg paused,
    output reg [11:0] step_size
);
    // Map selectable speeds onto fixed-point step sizes (Q8.4).
    always @(*) begin
        case (speed[2:0])
            3'd1: step_size = 2; // 0.125 pixels/frame
            3'd2: step_size = 8; // 0.5 pixels/frame
            3'd3: step_size = 12; // 0.75 pixels/frame
            3'd4: step_size = 16; // 1.0 pixels/frame
            3'd5: step_size = 20; // 1.25 pixels/frame
            3'd6: step_size = 24; // 1.5 pixels/frame
            default: step_size = 2;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            paused <= 0;
        end else begin
            // This determines if the animation is paused or not
            if (pause) begin
                paused <= 1;
            end else if (resume) begin
                paused <= 0;
            end
        end
    end

endmodule
