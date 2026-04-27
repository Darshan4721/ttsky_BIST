/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bist_controller (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  bist_status_t overall_result;

  bist_controller_top bist_controller (
      .clk(clk),
      .rst(rst_n),
      .enable(ui_in[0]),
      .bist_start(ui_in[1]),
      .overall_result(overall_result)
  );

  // Map the output
  assign uo_out[0] = overall_result.active;
  assign uo_out[1] = overall_result.running;
  assign uo_out[2] = overall_result.done;
  assign uo_out[3] = overall_result.pass;
  assign uo_out[4] = overall_result.failed;
  assign uo_out[7:5] = 3'b000;

  // IO pins not used as output
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0};

endmodule
