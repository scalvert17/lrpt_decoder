`timescale 1ns / 1ps
`default_nettype none

//TODO: figure out the offset 

module uw_sync_interleave_tb();

  parameter BITS_PER_FRAME = 80;
  parameter MAX_CORR_VAL = (8 * 32) + 1;
  parameter NUM_FRAMES = 32;

  // logic clk;
  // logic rst_in;
  // logic hard_inp;
  // logic valid_in;
  // logic [$clog2(BITS_PER_FRAME)-1:0] count;

  // logic valid_out;
  // logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset;
  // logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight;

  // uw_sync_derotate_int #(
  //    .BITS_PER_FRAME(80),
  //    .NUM_FRAMES(32),
  //     .MAX_CORR_VAL(8 * 32),
  //     .SYNC_WORD(8'h27)
  //   )sync (
  //   .clk(clk),
  //   .rst_in(rst_in),
  //   .hard_inp(hard_inp),
  //   .valid_in(valid_in),
  //   .valid_out(valid_out),
  //   .bit_offset(bit_offset),
  //   .max_offset_weight(max_offset_weight)
  // );
  logic clk;
  logic rst_in;
  logic hard_inp;
  logic valid_in;
  logic [$clog2(BITS_PER_FRAME)-1:0] count;

  // Debugging 
  logic [$clog2(NUM_FRAMES)-1:0] frame_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr;
  logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt;
  logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out;
  logic wea_b;
  logic [2:0] corr_count;

  logic valid_out;
  logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset;
  logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight;
  logic [7:0] valid_out_corr;
  logic [7:0] valid_in_corr;
  logic state_out;
  logic hard_inp_int;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_0;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_1;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_2;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_3;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_4;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_5;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_6;
  logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_7;

  
  logic debug_0_write_flag;



  uw_sync_derotate_int #(
     .BITS_PER_FRAME(80),
     .NUM_FRAMES(32),
      .MAX_CORR_VAL(MAX_CORR_VAL),
      .SYNC_WORD(8'h27)
    )sync (
    .clk(clk),
    .rst_in(rst_in),
    .hard_inp(hard_inp),
    .valid_in(valid_in),
    .valid_out(valid_out),
    .bit_offset(bit_offset),
    .max_offset_weight(max_offset_weight)
    // .frame_ctr(frame_ctr),
    // .offset_ctr(offset_ctr),
    // .offset_read_addr(offset_read_addr),
    // .offset_write_addr(offset_write_addr),
    // .write_wgt(write_wgt),
    // .read_wgt_out(read_wgt_out),
    // .wea_b(wea_b),
    // .corr_count(corr_count),
    // .valid_out_corr(valid_out_corr),
    // .state_out(state_out),
    // .valid_in_corr_out(valid_in_corr),
    // .debug_0_write_flag(debug_0_write_flag),
    // .weight_check_0(weight_check_0),
    // .weight_check_1(weight_check_1),
    // .weight_check_2(weight_check_2),
    // .weight_check_3(weight_check_3),
    // .weight_check_4(weight_check_4),
    // .weight_check_5(weight_check_5),
    // .weight_check_6(weight_check_6),
    // .weight_check_7(weight_check_7),
    // .hard_inp_int(hard_inp_int)
  );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk = !clk;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("uw_sync.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,uw_sync_interleave_tb);
    $display("Starting Sim"); //print nice message at start
    clk= 0;
    rst_in = 0;
    valid_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10

    count = 0;


    for (int i = 0; i<BITS_PER_FRAME * NUM_FRAMES; i=i+1)begin
      valid_in = 1;
      case (count)
        0: hard_inp = 0;
        1: hard_inp = 0;
        2: hard_inp = 1;
        3: hard_inp = 0;
        4: hard_inp = 0;
        5: hard_inp = 1;
        6: hard_inp = 1;
        7: hard_inp = 1;
        default: hard_inp = $random;
      endcase
      #10;
      if (count == BITS_PER_FRAME - 1) begin
        count = 0;
      end else  begin
        count = count + 1;
      
      end
    end
      #6000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
