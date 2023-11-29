`timescale 1ns / 1ps
`default_nettype none

/*
* Calculates the state metric for the 
*/
module acs_butterfly #(
    parameter TRANSITION_BIT = 1'b0, 
    parameter STATE_0 = 6'b000000, // State from the zero transition
    parameter STATE_1 = 6'b000000,
    parameter STATE_MET_WIDTH = 20
)(

  input wire clk,
  input wire sys_rst,
  input wire [STATE_MET_WIDTH-1:0] bm_0,
  input wire [STATE_MET_WIDTH-1:0] bm_1,
  input wire [STATE_MET_WIDTH-1:0] sm_0,
  input wire [STATE_MET_WIDTH-1:0] sm_1,
  input wire valid_in,

  output logic desc,
  output logic valid_out,
  output logic [STATE_MET_WIDTH-1:0] sm_out, 
  output logic [5:0] prev_state
);

  logic [STATE_MET_WIDTH-1:0] pm_0;
  logic [STATE_MET_WIDTH-1:0] pm_1;
  
  always_ff @(posedge clk) begin
    if (sys_rst) begin
      valid_out <= 0;
      desc <= 0;
      sm_out <= 0;
      prev_state <= 0;
    end else if (valid_in) begin
      valid_out <= 1;
      pm_0 = (bm_0 + sm_0 >= bm_0) ? bm_0 + sm_0 : 20'hFFFFF;
      pm_1 = (bm_1 + sm_1 >= bm_1) ? bm_1 + sm_1 : 20'hFFFFF;
      if (sm_0 < sm_1) begin
        sm_out <= pm_0;
        prev_state <= STATE_0;
      end else begin
        sm_out <= pm_1;
        prev_state <= STATE_1;
      end
      desc <= TRANSITION_BIT;
    end
  end


endmodule
`default_nettype wire

