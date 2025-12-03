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
    // Pass through speed value (1-6) as step_size.
    // For invalid speeds, default to 1.
    always @(*) begin
        step_size = ((speed >= 1) && (speed <= 6)) ? speed : 1;
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
