`timescale 1ns / 1ps
`default_nettype none

module viterbi_tb;

  logic clk;
  logic sys_rst;
  logic signed [7:0] soft_inp;
  logic valid_in_vit;
  logic ready_in;
  logic vit_desc;
  logic valid_out;
  logic normalization;
  logic [19:0] sm_0_debug;

  viterbi dut (
      .clk(clk),
      .sys_rst(sys_rst),
      .soft_inp(soft_inp),
      .valid_in_vit(valid_in_vit),
      .vit_desc(vit_desc),
      .normalization(normalization),
      .ready_in(ready_in),
      .sm_0_debug(sm_0_debug),
      .valid_out_vit(valid_out)
  );

  always begin
    #5 clk = ~clk;
  end

  initial begin
    $dumpfile("vcd/vit.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,viterbi_tb); //dump all variables in this module
    $display("Starting Sim"); //print nice message at start
    clk = 0;
    sys_rst = 1;
    valid_in_vit = 0;
    #10 
    sys_rst = 0;
    valid_in_vit = 1;
    soft_inp = 8'h00;
    #10
    $display("TESTING HERE");

    soft_inp = 8'hFF;
    #10

    #10;
    soft_inp = 8'h00;

    #10;
    soft_inp = 8'hBD;

    #10;
    soft_inp = 8'h11;

    #10;
    for (int i = 0; i < 1000; i++) begin
      soft_inp = $random;
      #10;
    end
    #10;
    $display("Simulation finished");
    $finish;
  end

endmodule
`default_nettype wire