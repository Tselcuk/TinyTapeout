// Returns a next_frame pulse and a step_size for the pattern to use
// next_frame will be locked at 60Hz, step_size varies based on the speed select and affects movements of the pattern
module speed_controller (
    input wire clk,
    input wire rst,
    input wire [2:0] speed,
    input wire pause,
    input wire resume,
    input wire frame_start,
    output reg next_frame,
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

    reg paused;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            paused     <= 0;
            next_frame <= 0;
        end else begin
            // This determines if the animation is paused or not
            if (pause) begin
                paused <= 1;
            end else if (resume) begin
                paused <= 0;
            end

            // This determines if the next frame pulse should be asserted
            // next_frame will only be asserted if we are not paused and need to advance to the next frame
            if (!paused && frame_start) begin
                next_frame <= 1;
            end else begin
                next_frame <= 0;
            end
        end
    end

endmodule
