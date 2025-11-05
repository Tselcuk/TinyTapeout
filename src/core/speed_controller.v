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
    output reg [2:0] step_size
);
    // Map selectable speeds onto fixed-point step sizes (Q1.2: 1 integer bit, 2 fractional bits).
    always @(*) begin
        case (speed[2:0])
            3'd1: step_size = 1; // 0.25 pixels/frame (1/4)
            3'd2: step_size = 2; // 0.5 pixels/frame (2/4)
            3'd3: step_size = 3; // 0.75 pixels/frame (3/4)
            3'd4: step_size = 4; // 1.0 pixels/frame (4/4)
            3'd5: step_size = 5; // 1.25 pixels/frame (5/4)
            3'd6: step_size = 6; // 1.5 pixels/frame (6/4)
            default: step_size = 1;
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
