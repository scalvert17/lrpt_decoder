`timescale 1ns / 1ps
`default_nettype none

module correlator_tb();

  parameter BITS_PER_FRAME = 80;
  parameter MAX_CORR_VAL = 8 * 32;
  parameter NUM_FRAMES = 32;

  logic clk;
  logic rst_in;
  logic inp_bit;
  logic [$clog2(MAX_CORR_VAL)-1:0] past_weight;
  logic valid_in;
  logic valid_out;
  logic [$clog2(MAX_CORR_VAL)-1:0] new_weight; 
  logic corr_bit;

  correlator #(
    .SYNC_WORD(8'h27)
  ) correl  (
    .clk(clk),
    .sys_rst(rst_in),
    .inp_bit(inp_bit), 
    .past_weight(past_weight),
    .valid_in(valid_in),
    .valid_out(valid_out),
    .new_weight(new_weight)
    // .corr_bit(corr_bit)
  );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk = !clk;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("correl.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,correlator_tb);
    $display("Starting Sim"); //print nice message at start
    clk= 0;
    valid_in = 0;
    #10;
    past_weight = 0;
    // for (int i = 0; i<8; i=i+1)begin
    //   valid_in = 1;
    //   inp_bit = 1;
    //   #10;
    // end
    valid_in = 1;
    inp_bit = 0;
    #10;
    inp_bit = 0;
    #10;
    inp_bit = 1;
    #10;
    inp_bit = 0;
    #10
    inp_bit = 0;
    #10;
    inp_bit = 1;
    #10;
    inp_bit = 1;
    #10;
    inp_bit = 1;
    #6000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
