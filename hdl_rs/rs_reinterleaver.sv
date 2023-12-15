`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
EXPECTATIONS WHILE WRITING I/Os
Right now, I'm expecting:
  one byte to be sent at a time (roughly every 100,000 clock cycles since 80 kb/s)
  a signal indicating a new cvcdu
  a signal indicating a new symbol
  AXI? communication protocol; the valid in/out stuff (NOT INCLUDING RIGHT NOW)

The interleaver will take in four 2-bit signals at a time and will output one byte at a time (since
interleaving depth=4).
*/

module rs_reinterleaver(
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,
  input wire [2:0] data_in_1,
  input wire [2:0] data_in_2,
  input wire [2:0] data_in_3,
  input wire [2:0] data_in_4,
  output wire [7:0] symbol_out
  );

endmodule

`default_nettype wire
