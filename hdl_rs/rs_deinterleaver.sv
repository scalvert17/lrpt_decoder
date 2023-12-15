`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
EXPECTATIONS WHILE WRITING I/Os
Right now, I'm expecting:
  one byte to be sent at a time (roughly every 100,000 clock cycles since 80 kb/s)
  a signal indicating a new cvcdu
  a signal indicating a new symbol
  AXI? communication protocol; the valid in/out stuff (NOT INCLUDING RIGHT NOW)

The deinterleaver will take in one symbol at a time and will produce 4 different output streams (since
interleaving depth=4).

The deinterleaver will take in one symbol at a time and decide 
*/

module rs_deinterleaver(
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,
  input wire [7:0] symbol_in,
  output wire [1:0] data_out_1,
  output wire [1:0] data_out_2,
  output wire [1:0] data_out_3,
  output wire [1:0] data_out_4
  );

endmodule

`default_nettype wire
