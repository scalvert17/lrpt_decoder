`timescale 1ns / 1ps
`default_nettype none

module rs_syndromes_tb();

  logic clk_in;        //clock input
  logic rst_in;        //active low asynchronous reset
  logic new_cvcdu;
  logic [7:0] r_in;
  logic data_valid_in;

  logic [7:0] s1;    //Syndromes; coeffs of S(x)
  logic [7:0] s2;
  logic [7:0] s3;
  logic [7:0] s4;
  logic [7:0] s5;
  logic [7:0] s6;
  logic [7:0] s7;
  logic [7:0] s8;
  logic [7:0] s9;
  logic [7:0] s10;
  logic [7:0] s11;
  logic [7:0] s12;
  logic [7:0] s13;
  logic [7:0] s14;
  logic [7:0] s15;
  logic [7:0] s16;
  logic [7:0] s17;
  logic [7:0] s18;
  logic [7:0] s19;
  logic [7:0] s20;
  logic [7:0] s21;
  logic [7:0] s22;
  logic [7:0] s23;
  logic [7:0] s24;
  logic [7:0] s25;
  logic [7:0] s26;
  logic [7:0] s27;
  logic [7:0] s28;
  logic [7:0] s29;
  logic [7:0] s30;
  logic [7:0] s31;
  logic [7:0] s32;
  logic data_valid_out;


  //instantiate rs_syndromes
  rs_syndromes rs_syndromes_inst (
    .clk_in (clk_in),
    .rst_in (rst_in),
    .new_cvcdu (new_cvcdu),
    .r_in (r_in),
    .data_valid_in (data_valid_in),
    .s1 (s1),
    .s2 (s2),
    .s3 (s3),
    .s4 (s4),
    .s5 (s5),
    .s6 (s6),
    .s7 (s7),
    .s8 (s8),
    .s9 (s9),
    .s10 (s10),
    .s11 (s11),
    .s12 (s12),
    .s13 (s13),
    .s14 (s14),
    .s15 (s15),
    .s16 (s16),
    .s17 (s17),
    .s18 (s18),
    .s19 (s19),
    .s20 (s20),
    .s21 (s21),
    .s22 (s22),
    .s23 (s23),
    .s24 (s24),
    .s25 (s25),
    .s26 (s26),
    .s27 (s27),
    .s28 (s28),
    .s29 (s29),
    .s30 (s30),
    .s31 (s31),
    .s32 (s32),
    .data_valid_out (data_valid_out)
    );

  //switch clock every 5 ns...100 MHz clock
  always begin
    #5;
    clk_in = !clk_in;
  end


  initial begin
    $dumpfile("rs_syndromes.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,rs_syndromes_tb); //store everything at the current level and below
    $display("Starting Sim"); //print nice message
    clk_in = 0; //initialize clk (super important)
    rst_in = 0; //initialize rst (super important)
    #10  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #10; //hold high for a few clock cycles
    rst_in = 0;


    data_valid_in = 1;
    new_cvcdu = 1;
    r_in = 8'hFF;
    #10;
    new_cvcdu = 0;

    /* Message is all 1s; parity is all 1s; syndromes should be 0
    for (int i=1; i<256; i=i+1) begin
      r_in = 8'd18;
      #10;
    end
    */

    r_in = 8'd2;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd250;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd98;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd164;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd129;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd123;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd1;
    #10;
    r_in = 8'd254;
    #10;
    r_in = 8'd45;
    #10;
    r_in = 8'd71;
    #10;
    r_in = 8'd110;
    #10;
    r_in = 8'd154;
    #10;
    r_in = 8'd239;
    #10;
    r_in = 8'd158;
    #10;
    r_in = 8'd216;
    #10;
    r_in = 8'd74;
    #10;
    r_in = 8'd48;
    #10;
    r_in = 8'd159;
    #10;
    r_in = 8'd222;
    #10;
    r_in = 8'd171;
    #10;
    r_in = 8'd65;
    #10;
    r_in = 8'd21;
    #10;
    r_in = 8'd130;
    #10;
    r_in = 8'd154;
    #10;
    r_in = 8'd93;
    #10;
    r_in = 8'd26;
    #10;
    r_in = 8'd199;
    #10;
    r_in = 8'd213;
    #10;
    r_in = 8'd32;
    #10;
    r_in = 8'd206;
    #10;
    r_in = 8'd173;
    #10;
    r_in = 8'd221;
    #10;
    r_in = 8'd20;
    #10;
    r_in = 8'd74;
    #10;
    r_in = 8'd161;
    #10;
    r_in = 8'd180;
    #10;
    r_in = 8'd89;
    #10;
    r_in = 8'd95;
    #10;
    r_in = 8'd220;
    #10;
    #10;
    #5200;

    $finish;
  end

endmodule
`default_nettype wire