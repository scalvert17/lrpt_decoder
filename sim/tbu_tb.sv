`timescale 1ns / 1ps
`default_nettype none

module tbu_tb;
  parameter NUM_STATES = 64;
  logic clk;
  logic sys_rst;
  logic [5:0] prev_state [NUM_STATES-1:0];
  logic desc [NUM_STATES-1:0];
  logic valid_in;
  logic vit_desc; 
  logic valid_out;

/* module tbu ( */
/*   input wire clk, */
/*   input wire sys_rst, */
/*   input wire [5:0] prev_state [NUM_STATES-1:0], */
/*   input wire desc [NUM_STATES-1:0], */
/*   //! Store as {desc, prev_state}. The top 8 bits should only be padding */ 
/*   input wire valid_in, // Should be high at most once for any two consecutive cycles */ 
/*   output vit_desc, */
/*   output valid_out */
/* ); */

  tbu dut (
      .clk(clk),
      .sys_rst(sys_rst),
      .prev_state(prev_state),
      .desc(desc),
      .valid_in(valid_in),
      .vit_desc(vit_desc),
      .valid_out(valid_out)
  );

  always begin
    #5 clk = ~clk;
  end

  initial begin
    $dumpfile("vcd/tbu.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,tbu_tb); //dump all variables in this module
    $display("Starting Sim"); //print nice message at start
    clk = 0;
    sys_rst = 1;
    valid_in = 0;
    #10 
    sys_rst = 0;
    for (int j = 0; j < 400; j = j + 1) begin
      valid_in = ~valid_in;
      for (int i = 0; i < NUM_STATES; i = i + 1) begin
        prev_state[i] = $random;
        desc[i] = $random;
      end
      #10;
    end
    
    #10;
    $display("Simulation finished");
    $finish;
  end

endmodule
`default_nettype wire
