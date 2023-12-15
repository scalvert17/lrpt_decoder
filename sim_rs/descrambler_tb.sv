`timescale 1ns / 1ps
`default_nettype none

module descrambler_tb;

  //logics for inputs and outputs
  logic clk_in;
  logic rst_in;
  logic cvcdu_new;
  logic data_valid_in;
  logic [7:0] byte_in;
  logic [7:0] byte_out;
  logic data_valid_out;

  descrambler uut (.clk_in(clk_in),
                   .rst_in(rst_in),
                   .cvcdu_new(cvcdu_new),
                   .data_valid_in(data_valid_in),
                   .byte_in(byte_in),
                   .byte_out(byte_out),
                   .data_valid_out(data_valid_out));

  always begin
    #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
    clk_in = !clk_in;
  end


  //begin the simulation
  initial begin
    $dumpfile("descrambler.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,descrambler_tb); //store everything at the current level and below
    $display("Starting Sim"); //print nice message
    clk_in = 0; //initialize clk (super important)
    rst_in = 0; //initialize rst (super important)
    #10  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #10; //hold high for a few clock cycles
    rst_in = 0;
    //Ready to go

    byte_in = 8'b0000_0000;
    
    for (int i = 0; i<300; i= i+1)begin
      byte_in = 8'b0000_0000;
      data_valid_in = 1;
      #10;
      data_valid_in = 0;

      for (int j=0; j<120; j=j+1) begin
        #10;
        if (data_valid_out) begin
          $display("%8b", byte_out);
        end
      end

      #50;
    end
    $finish;

  end
endmodule //lfsr_8_tb

`default_nettype wire
