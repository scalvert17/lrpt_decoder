`timescale 1ns / 1ps
`default_nettype none

/*
* 
*/
module bmu # (
  parameter EXP_OBS_OUT = 2'b00, // EXP_OBS_OUT[1] is I, EXP_OBS_OUT[0] is Q
  parameter STATE_MET_WIDTH = 20
)(
  input wire clk,
  input wire sys_rst,
  input wire  [7:0] input_i, // Should be offset binary
  input wire [7:0] input_q, 
  // output logic  [31:0] debug,
  output logic [STATE_MET_WIDTH-1:0] met_out // Should be offset binary
);

  // Convert from binary offset to 2's complement
  parameter EXP_OBS_OUT_I = EXP_OBS_OUT[1] ? 8'hFF : 8'h00; 
  parameter EXP_OBS_OUT_Q = EXP_OBS_OUT[0] ? 8'hFF : 8'h00;

  logic [7:0] met_out_i;
  logic [7:0] met_out_q;

  // be proportional to log-likelihood
  always_comb begin 
      if (EXP_OBS_OUT[1]) begin 
        met_out_i = 8'hFF - input_i;
     end else begin
        met_out_i = input_i;
      end
      if (EXP_OBS_OUT[0]) begin 
        met_out_q = 8'hFF - input_q;
      end else begin
        met_out_q = input_q;
      end
      met_out = met_out_i**2 + met_out_q**2;
  end

  // Euclidean error metric with offest binary. This should still
  /* // be proportional to log-likelihood */
  /* always_ff @(posedge clk) begin */
  /*   if (sys_rst) begin */
  /*     met_out <= 0; */
  /*   end else begin */
  /*     if (EXP_OBS_OUT[1]) begin */ 
  /*       met_out_i = 8'hFF - input_i; */
  /*       // debug = met_out_i; */
  /*    end else begin */
  /*       met_out_i = input_i; */
  /*     end */

  /*     if (EXP_OBS_OUT[0]) begin */ 
  /*       met_out_q = 8'hFF - input_q; */
  /*     end else begin */
  /*       met_out_q = input_q; */
  /*     end */

  /*     met_out <= met_out_i**2 + met_out_q**2; */
      
  /*   end */
  /* end */

endmodule
`default_nettype wire

