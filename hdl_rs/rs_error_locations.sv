`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
EXPECTATIONS WHILE WRITING I/Os
Right now, I'm expecting:
  one byte to be sent at a time (roughly every 100,000 clock cycles since 80 kb/s)
  a signal indicating a new cvcdu
  a signal indicating a new symbol
  AXI? communication protocol; the valid in/out stuff (NOT INCLUDING RIGHT NOW)

The rs_error_polynomial module will take in all the syndromes and idk what after that
Chien search
*/

module rs_error_locations(
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,
  input wire [7:0] lambda,
  input wire [7:0] omega,
  input wire [7:0] D,
  input wire search,
  input wire load,
  input wire shorten,
  output logic [7:0] error,
  output logic [7:0] alpha,
  output logic [7:0] even
  );

endmodule



module rs_inverse(
  input wire [7:0] x,
  output logic [7:0] y
  );

endmodule
`default_nettype wire
