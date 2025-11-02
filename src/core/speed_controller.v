/* Speed Controller
 *
 * Generates a single-cycle next_frame pulse based on a selectable speed and
 * pause/resume controls. Intended to drive animation/frame advancement in
 * downstream modules like pattern generators.
 */
module speed_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] speed,
    input  wire       pause,
    input  wire       resume,
    output reg        next_frame
);

    reg        paused;
    reg [23:0] rate_counter;
    reg [23:0] update_interval;

    wire [2:0] speed_select;
    wire _unused_speed_upper = |speed[7:3];

    // Bound lowest three bits to 1..6, default to 3 when 0
    assign speed_select = (speed[2:0] == 3'd0) ? 3'd3 :
                          (speed[2:0] >  3'd6) ? 3'd6 :
                                                 speed[2:0];

    always @(*) begin
        case (speed_select)
            3'd1: update_interval = 24'd1_600_000;
            3'd2: update_interval = 24'd800_000;
            3'd3: update_interval = 24'd400_000;
            3'd4: update_interval = 24'd200_000;
            3'd5: update_interval = 24'd120_000;
            3'd6: update_interval = 24'd80_000;
            default: update_interval = 24'd400_000;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            paused <= 1'b0;
            rate_counter <= 24'd0;
            next_frame <= 1'b0;
        end else begin
            // Defaults
            next_frame <= 1'b0;

            // Pause/Resume state machine
            if (resume && paused) begin
                paused <= 1'b0;
            end else if (pause && !paused) begin
                paused <= 1'b1;
            end

            if (!paused) begin
                if (rate_counter >= update_interval) begin
                    rate_counter <= 24'd0;
                    next_frame <= 1'b1; // one-cycle pulse
                end else begin
                    rate_counter <= rate_counter + 24'd1;
                end
            end
        end
    end

endmodule


