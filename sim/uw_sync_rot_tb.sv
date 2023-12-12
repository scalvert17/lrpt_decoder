`timescale 1ns / 1ps
`default_nettype none


module uw_sync_rot_tb();
  parameter BYTES_PER_FRAME = 80;
  parameter NUM_FRAMES = 32;
  logic clk;
  logic rst_in;
  logic [7:0] soft_inp;
  logic valid_in;
  logic ready_tx;
  logic ready_in;
  logic valid_out;
  logic [7:0] soft_out_0;
  logic [7:0] soft_out_1;

 uw_sync_rot sync (
   .clk(clk),
   .rst_in(rst_in),
   .soft_inp(soft_inp),
   .valid_in(valid_in),
   .ready_in(ready_in),
   .ready_tx(ready_tx),
   .valid_out(valid_out),
   .soft_out_0(soft_out_0),
   .soft_out_1(soft_out_1)
);

  logic [8*BYTES_PER_FRAME*NUM_FRAMES-1:0] frames;

  function [7:0] convertBitToOutput(input bit inputBit);
    if (inputBit == 1'b1)
      convertBitToOutput = 8'h7f;
    else
      convertBitToOutput = 8'h80;
  endfunction
  
  task create_frames;
    input [7:0] sync_word;
    input integer num_frames;
    input integer offset; // in bytes
    integer i, j;
    integer count;
    begin
      count = 0;
      for (j = 0; j < offset; j = j + 1) begin
        frames[8*j +: 8] = $random;
      end

      for (i = 0; i < num_frames * BYTES_PER_FRAME - offset ; i = i + 1) begin
        case (count)
          0: frames[(i + offset)*8 +: 8] = convertBitToOutput(sync_word[7]);
          1: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[6]);
          2: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[5]);
          3: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[4]);
          4: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[3]);
          5: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[2]);
          6: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[1]);
          7: frames[(i + offset) * 8 +: 8] = convertBitToOutput(sync_word[0]);
          default: frames[(i + offset)*8 +: 8] = $random;
        endcase
        count = (count < BYTES_PER_FRAME - 1) ? count + 1 : 0;
      end
    end
  endtask

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk = !clk;
  end
  //initial block...this is our test simulation
  int offset;
  int counter;
  
  initial begin
    $dumpfile("uw_sync_rot.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,uw_sync_rot_tb);
    $display("Starting Sim"); //print nice message at start
      clk= 0;
      rst_in = 0;
      valid_in = 0;
      #10;
      rst_in = 1;
      #10;
      rst_in = 0;
      #10
      offset = 0; // In bytes
      ready_tx = 0;
      $display("simulating offset 0");
      for (int i = 0; i < 3; i = i + 1) begin
        create_frames(8'h27, NUM_FRAMES, offset);

        while (!ready_in) begin
          $display("Waiting for ready_in");
          #10;
        end

        for (int i = 0; i< BYTES_PER_FRAME * NUM_FRAMES - offset; i=i+1)begin
          valid_in = 1;
          soft_inp = frames[8*i +: 8];
          #10;
        end
        // Per module spec, we need to set valid_in to 0 once
        valid_in = 0;

        ready_tx = 1;
        counter = 0;
        #10;
        for (int i = 0; i < BYTES_PER_FRAME * NUM_FRAMES - offset; i = i + 2) begin
          ready_tx = 0;
          #10;
          ready_tx = 1;
          while (!valid_out) begin
            #10;
          end
          if (valid_out) begin
            $display("I: %d", i);
            assert (frames[8*i +: 8] == soft_out_0)  
              else $error(1, "Expected (0) correct out %d instead got %d on iteration %d", 
                frames[8*i +:8], soft_out_0, i);
            assert (frames[8*(i+1) +: 8] == soft_out_1) 
              else $error(1, "Expected (1) correct out %d instead got %d on iteration %d", 
                frames[8*(i+1) +:8], soft_out_1, i);
          end
          #10;
        end
      end
    #10000;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
