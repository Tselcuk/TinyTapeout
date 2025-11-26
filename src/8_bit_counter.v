module counter8bit_tristate (
    input  wire        clk,
    input  wire        reset,          // Asynchronous active-high reset
    input  wire        parallel_load,  // Load enable
    input  wire [7:0]  data_in,        // Data to load in parallel
    input  wire        out_enable,     // Tri-state output enable
    output wire [7:0]  q_bus           // Tri-state output
);

    // Internal 8-bit counter
    reg [7:0] q;

    // asynchronous reset, synchronous load
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 8'b0;                 // Reset
        else if (parallel_load)
            q <= data_in;              // Parallel load
        else
            q <= q + 1'b1;             // Increment
    end

    // Tri-state output
    assign q_bus = out_enable ? q : 8'bz;

endmodule
