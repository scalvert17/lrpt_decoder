`timescale 1ns / 1ps
`default_nettype none

module rs_error_polynomial_tb();

  logic clk_in;        //clock input
  logic rst_in;        //active low asynchronous reset
  logic new_cvcdu;
  logic [7:0] syndrome [31:0];
  logic data_valid_in;
  logic [7:0] lambda [16:0];


  //instantiate rs_syndromes
  rs_error_polynomial rs_error_polynomial_inst (
    .clk_in (clk_in),
    .rst_in (rst_in),
    .new_cvcdu (new_cvcdu),
    .syndrome (syndrome),
    .data_valid_in (data_valid_in),
    .lambda (lambda)
    );

  //switch clock every 5 ns...100 MHz clock
  always begin
    #5;
    clk_in = !clk_in;
  end


  //Assign the syndrome values output by the rs_syndromes_tb.
  //GF(2^8) elements represented as decimal values
  always_comb begin
    syndrome[0] = 23;
    syndrome[1] = 75; 
    syndrome[2] = 152;
    syndrome[3] = 55;
    syndrome[4] = 84;
    syndrome[5] = 92;
    syndrome[6] = 239;
    syndrome[7] = 58;
    syndrome[8] = 75;
    syndrome[9] = 162;
    syndrome[10] = 90;
    syndrome[11] = 28;
    syndrome[12] = 236;
    syndrome[13] = 127;
    syndrome[14] = 202;
    syndrome[15] = 8;
    syndrome[16] = 64;
    syndrome[17] = 67;
    syndrome[18] = 119;
    syndrome[19] = 31;
    syndrome[20] = 77;
    syndrome[21] = 17;
    syndrome[22] = 190;
    syndrome[23] = 182;
    syndrome[24] = 96;
    syndrome[25] = 99;
    syndrome[26] = 18;
    syndrome[27] = 38;
    syndrome[28] = 31;
    syndrome[29] = 119;
    syndrome[30] = 216;
    syndrome[31] = 138;
  end


  initial begin
    $dumpfile("rs_error_polynomial.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,rs_error_polynomial_tb); //store everything at the current level and below
    $display("Starting Sim"); //print nice message
    clk_in = 0; //initialize clk (super important)
    rst_in = 0; //initialize rst (super important)
    #10  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #10; //hold high for a few clock cycles
    rst_in = 0;


    new_cvcdu = 1;
    data_valid_in = 1;
    #10;
    new_cvcdu = 0;
    data_valid_in = 0;
    #20000;


    $finish;
  end

endmodule
`default_nettype wire