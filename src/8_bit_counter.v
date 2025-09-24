module sync_counter (
    input  wire        clk,
    input  wire        reset,          // Synchronous active-high reset
    input  wire        parallel_load,  // Load enable
    input  wire [7:0]  data_in,        // Data to load in parallel
    output reg  [7:0]  q               // 8-bit counter output
);

    always @(posedge clk) begin
        if (reset)
            q <= 8'b0;                // Reset counter to 0
        else if (parallel_load)
            q <= data_in;             // Load data in parallel
        else
            q <= q + 1'b1;            // Increment counter
    end

endmodule
