`timescale 1ns / 1ps
`default_nettype none

//TODO: figure out the offset 

module uw_interleave_full_tb();

  parameter BITS_PER_FRAME = 80;
  parameter MAX_CORR_VAL = (8 * 32) + 1;
  parameter NUM_FRAMES = 32;


  logic clk;
  logic rst_in;
  logic hard_inp;
  logic valid_in;

  logic valid_out;
  logic ready_rx;
  logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset;
  logic [3:0] rotation;

  localparam [0:31] SYNC_WORDS = 32'h274ED8B1;  // sync words {8'h27, 8'h4E, 8'hD8, 8'hB1}

  // logic [7:0] valid_out_corr;
  // logic [7:0] valid_in_corr;
  // logic state_out;
  // logic hard_inp_int;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_0;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_1;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_2;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_3;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_4;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_5;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_6;
  // logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_7;
  // logic debug_0_write_flag;

  int count;
  int rot_num_offset;

  logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight;
  logic state_out;

  uw_deinterleave #(
     .BITS_PER_FRAME(BITS_PER_FRAME),
     .NUM_FRAMES(NUM_FRAMES),
      .MAX_CORR_VAL(MAX_CORR_VAL)
    ) sync (
    .clk(clk),
    .rst_in(rst_in),
    .hard_inp(hard_inp),
    .valid_in(valid_in),
    .valid_out(valid_out),
    .ready_rx(ready_rx),
    .bit_offset(bit_offset),
    .max_offset_weight(max_offset_weight),
    .rotation(rotation)
  );

  logic [BITS_PER_FRAME*NUM_FRAMES-1:0] frames;
  
  task create_frames;
    input [7:0] sync_word;
    input integer num_frames;
    input integer offset;
    integer i, j;
    integer count;
    begin
      count = 0;
      for (j = 0; j < offset; j = j + 1) begin
        frames[j] = $random;
      end

      for (i = 0; i < num_frames * BITS_PER_FRAME - offset; i = i + 1) begin
        case (count)
          0: frames[i + offset] = sync_word[7];
          1: frames[i + offset] = sync_word[6];
          2: frames[i + offset] = sync_word[5];
          3: frames[i + offset] = sync_word[4];
          4: frames[i + offset] = sync_word[3];
          5: frames[i + offset] = sync_word[2];
          6: frames[i + offset] = sync_word[1];
          7: frames[i + offset] = sync_word[0];
          default: frames[i + offset] = $random;
        endcase
        count = (count < BITS_PER_FRAME - 1) ? count + 1 : 0;
      end
    end
  endtask

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk = !clk;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("sync_full.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,uw_interleave_full_tb);
    $display("Starting Sim"); //print nice message at start
      clk= 0;
      rst_in = 0;
      valid_in = 0;
      #10;
      rst_in = 1;
      #10;
      rst_in = 0;
      #10
    $display("Simulating rotation 0");
    for (int rot_num = 0; rot_num < 4; rot_num = rot_num + 1) begin;

      $display("Simulating rotation %d", rot_num);
      create_frames(SYNC_WORDS[rot_num*8 +: 8], NUM_FRAMES, 0);

      while (!ready_rx) begin
        $display("Waiting for ready_rx");
        #10;
      end

      for (int i = 0; i<BITS_PER_FRAME * NUM_FRAMES; i=i+1)begin
        valid_in = 1;
        hard_inp = frames[i];
        #10;
      end
      // Per module spec, we need to set valid_in to 0 once
      valid_in = 0;

      while (!valid_out) begin
        #10;
      end
      assert (bit_offset == 0) else $fatal(1, "bit_offset is not 0, got %d", bit_offset);
      assert (rotation == rot_num) else $fatal(1, "rotation is not %d, got %d", rot_num, rotation);
    end

    #10;

    // Testing offset
    rot_num_offset = 0;
    $display("*****Testing all offsets*****");
    for (int offset_test = 0; offset_test < BITS_PER_FRAME; offset_test = offset_test + 1) begin;
      $display("Simulating rotation %d with offset: %d", rot_num_offset, offset_test);
      create_frames(SYNC_WORDS[rot_num_offset*8 +: 8], NUM_FRAMES, offset_test);

      while (!ready_rx) begin
        // $display("Waiting for ready_rx");
        #10;
      end

      for (int i = 0; i<BITS_PER_FRAME * NUM_FRAMES; i=i+1)begin
        valid_in = 1;
        hard_inp = frames[i];
        #10;
      end
      // Per module spec, we need to set valid_in to 0 once
      valid_in = 0;
      while (!valid_out) begin
        #10;
      end
      assert (bit_offset == offset_test) else $fatal(1, "bit_offset is not %d, got %d", 
        offset_test, bit_offset);
      assert (rotation == rot_num_offset) else $fatal(1, "rotation is not %d, got %d", rot_num_offset, rotation);
      rot_num_offset = (rot_num_offset < 3) ? rot_num_offset + 1 : 0;
    end
    #10000;
    
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
