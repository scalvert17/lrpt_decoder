`timescale 1ns / 1ps
`default_nettype none

/*
* 
*/
module tbu # (
    parameter NUM_STATES = 64,
    parameter S,
    parameter X_MIN,
    parameter B,
    parameter K
)(
  input wire clk,
  input wire sys_rst,
  input wire [5:0] prev_state [NUM_STATES-1:0],
  input wire desc [NUM_STATES-1:0],
  input wire valid_in,
  output vit_desc
);



endmodule
`default_nettype wire

