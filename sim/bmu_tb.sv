`timescale 1ns / 1ps
`default_nettype none

module bmu_tb;

  logic clk;
  logic sys_rst;
  logic [7:0] input_i;
  logic [7:0] input_q;
  logic [17:0] met_out;
  logic [31:0] debug;

  bmu #(.EXP_OBS_OUT(2'b11)) u_bmu (
    .clk(clk),
    .sys_rst(sys_rst),
    .input_i(input_i),
    .input_q(input_q),
    // .debug(debug),
    .met_out(met_out)
  );

  always begin
    #5 clk = ~clk;
  end

  initial begin
    $dumpfile("vcd/bmu.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,bmu_tb);
    $display("Starting Sim"); //print nice message at start
    clk = 0;
    sys_rst = 1;
    #10 
    sys_rst = 0;
    input_i = 8'h00;
    input_q = 8'h00;
    #10
    $display("TESTING HERE");

    input_i = 8'hFF;
    input_q = 8'hFF;
    #10

    #10;
    input_i = 8'hFF;
    input_q = 8'h00;

    #10;
    input_i = 8'h00;
    input_q = 8'hFF;

    #10;
    input_i = 8'h11;
    input_q = 8'h00;

    #10;
    assert (met_out == 18'b11101110**2) else $error("in correct got %b", met_out);

    #10;
    $display("Simulation finished");
    $finish;
  end

endmodule
`default_nettype wire