`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
The Reed-Solomon top level module will govern the deinterleaver, all Reed-Solomon modules, and the interleaver.
Expected inputs are the outputs of descrambler. Output should be [idk, at least a symbol]
*/

module rs_top_level(
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,
  input wire [7:0] symbol_in,
  output wire [7:0] symbol_out
  );

endmodule

`default_nettype wire
