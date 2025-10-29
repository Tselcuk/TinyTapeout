/*
 * Copyright (c) 2024 Tolga Selcuk and Joshua Zhang
 * SPDX-License-Identifier: Apache-2.0
 *
 * WatPixels - VGA Demoscene Project
 */

/* verilator lint_off DECLFILENAME */
`default_nettype none

module tt_um_watpixels (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Instantiate the WatPixels top-level module
  watpixels_top u_watpixels (
      .ui_in   (ui_in),
      .uo_out  (uo_out),
      .uio_in  (uio_in),
      .uio_out (uio_out),
      .uio_oe  (uio_oe),
      .ena     (ena),
      .clk     (clk),
      .rst_n   (rst_n)
  );

endmodule

`default_nettype wire
/* verilator lint_on DECLFILENAME */
