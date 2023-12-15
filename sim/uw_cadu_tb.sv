`timescale 1ns / 1ps
`default_nettype none


module uw_cadu_tb();

	parameter BITS_PER_FRAME = 1024 * 8;
  parameter MAX_CORR_VAL = (8 * 32) + 1;
  parameter NUM_FRAMES = 8;


  logic clk;
  logic rst_in;
  logic hard_inp;
  logic valid_in;

  logic valid_out;
  logic ready_rx;
  logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset;

  localparam [31:0] SYNC_WORD = 32'h1ACFFC1D;


  int count;
  int rot_num_offset;

  logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight;
  logic state_out;

  uw_cadu #(
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
    .max_offset_weight(max_offset_weight)
  );

  logic [BITS_PER_FRAME*NUM_FRAMES-1:0] frames;
  
  task create_frames;
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
          0: frames[i + offset] = SYNC_WORD[31];
          1: frames[i + offset] = SYNC_WORD[30];
          2: frames[i + offset] = SYNC_WORD[29];
          3: frames[i + offset] = SYNC_WORD[28];
          4: frames[i + offset] = SYNC_WORD[27];
          5: frames[i + offset] = SYNC_WORD[26];
          6: frames[i + offset] = SYNC_WORD[25];
          7: frames[i + offset] = SYNC_WORD[24];
          8: frames[i + offset] = SYNC_WORD[23];
          9: frames[i + offset] = SYNC_WORD[22];
          10: frames[i + offset] = SYNC_WORD[21];
          11: frames[i + offset] = SYNC_WORD[20];
          12: frames[i + offset] = SYNC_WORD[19];
          13: frames[i + offset] = SYNC_WORD[18];
          14: frames[i + offset] = SYNC_WORD[17];
          15: frames[i + offset] = SYNC_WORD[16];
          16: frames[i + offset] = SYNC_WORD[15];
          17: frames[i + offset] = SYNC_WORD[14];
          18: frames[i + offset] = SYNC_WORD[13];
          19: frames[i + offset] = SYNC_WORD[12];
          20: frames[i + offset] = SYNC_WORD[11];
          21: frames[i + offset] = SYNC_WORD[10];
          22: frames[i + offset] = SYNC_WORD[9];
          23: frames[i + offset] = SYNC_WORD[8];
          24: frames[i + offset] = SYNC_WORD[7];
          25: frames[i + offset] = SYNC_WORD[6];
          26: frames[i + offset] = SYNC_WORD[5];
          27: frames[i + offset] = SYNC_WORD[4];
          28: frames[i + offset] = SYNC_WORD[3];
          29: frames[i + offset] = SYNC_WORD[2];
          30: frames[i + offset] = SYNC_WORD[1];
          31: frames[i + offset] = SYNC_WORD[0];
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
    $dumpfile("cadu_uw.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,uw_cadu_tb); //dump all variables in this module
    $display("Starting Sim"); //print nice message at start
    clk= 0;
    rst_in = 0;
    valid_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10

    create_frames(NUM_FRAMES, 0);

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
    #10;

    // Testing offset
    $display("*****Testing all offsets*****");
    for (int offset_test = 0; offset_test < BITS_PER_FRAME; offset_test = offset_test + 1) begin;
      $display("Simulating  offset: %d", offset_test);
      create_frames(NUM_FRAMES, offset_test);

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
    end
    #10000;
    
    $display("Simulation finished");
    $finish;
  end

endmodule
`default_nettype wire
