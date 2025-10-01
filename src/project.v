/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ui_in bit map:
  // ui_in[0] = parallel_load
  // ui_in[1] = out_enable
  // ui_in[7:2] = reserved for future use

  wire parallel_load = ui_in[0];
  wire out_enable    = ui_in[1];

  // Adapt TT active-low reset to our module's active-high reset
  wire reset = ~rst_n;

  // Wires to observe the internal count even when tri-stated on pads
  wire [7:0] q_bus_internal;

  // Instantiate your counter
  counter8bit_tristate u_cnt (
      .clk(clk),
      .reset(reset),                // active high
      .parallel_load(parallel_load),
      .data_in(uio_in),             // load value comes from uio_in[7:0]
      .out_enable(out_enable),      // controls tri-state behavior
      .q_bus(q_bus_internal)        // internal view of the tri-state bus
  );

  // Drive the bidirectional user IO pads with tri-state
  // TT expects uio_out to carry data and uio_oe to control the pad driver (1=drive)
  assign uio_out = q_bus_internal;
  assign uio_oe  = {8{out_enable}};

  // Also mirror the count on the dedicated outputs so you can see it even when tri-stated
  assign uo_out  = q_bus_internal;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule

`default_nettype wire
