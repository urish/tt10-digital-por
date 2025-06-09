/*
 * Copyright (c) 2025 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_urish_por (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:2] = 0;
  assign uio_out = 0;
  assign uio_oe = 0;

  por_digital por_digital_0 (
      .clk(clk),
      .reset_n(uo_out[0])
  );

  por_digital #(
      .DELAY_BITS (10),
      .DELAY_CODE (10'h300),
      .DELAY_TAP_H(9),
      .DELAY_TAP_L(6)
  ) por_digital_1 (
      .clk(clk),
      .reset_n(uo_out[1])
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, rst_n, 1'b0};

endmodule
