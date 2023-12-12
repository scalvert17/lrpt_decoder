`default_nettype none
`timescale 1ns/1ps

/*
* This module recieves as input soft I/Q data, performs correlation with a set of 
* synchronization words and outputs 1024 bit frames of interleaved data. Each frame is 80 bits 
* including the 8 bit UW. Every two bytes has an I 8-bit word, followed by an 8-bit Q word. Output 
* is derotated.
*
* 
* Expects valid_in to be high for BITS_PER_FRAME * NUM_FRAMES cycles.  
* After these cycles valid_in must be asserted low until uw_deinterleave outputs ready_rx high
*/
module uw_sync_rot #(
  parameter INPUT_SIZE = 8 // Each reading is 8 bit vaule
) (
  input wire clk,
  input wire rst_in,
  input wire signed [INPUT_SIZE-1:0] soft_inp,
  input wire valid_in,
  input wire ready_tx, // downstream module ready to recieve 

  output logic ready_in,
  output logic valid_out,
  output logic signed [INPUT_SIZE-1:0] soft_out_0,
  output logic signed [INPUT_SIZE-1:0] soft_out_1
);

  parameter BITS_PER_FRAME = 80; // Hard decision
  parameter NUM_FRAMES = 32;// 32 frames each 80 bytes 
  // o
  typedef enum {
    IDLE = 0,
    READ = 1,
    WAIT_SYNC = 2,
    OUT_READ1 = 3,
    OUT_READ2 = 4,
    OUT_COMP = 5,
    OUT_LAST = 6
  } full_states;

  typedef enum {
    P_0 = 0,
    P_90 = 1,
    P_180 = 2,
    P_270 = 3
  } phase;

  logic [$clog2(BITS_PER_FRAME * NUM_FRAMES)-1:0] inp_count;
  full_states state;

  // For uw_sync module
  logic sync_ready;
  logic valid_in_sync;
  logic hard_inp;
  logic valid_out_sync;
  logic [1:0] sync_rot;
  logic [$clog2(BITS_PER_FRAME)-1:0] sync_offset;
  

  logic [1:0] rot;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset;
  logic pair_flag;
  
  uw_deinterleave #(
    .BITS_PER_FRAME(BITS_PER_FRAME),
    .NUM_FRAMES(NUM_FRAMES) 
  ) sync (
    .clk(clk),
    .rst_in(rst_in),
    .hard_inp(hard_inp),
    .valid_in(valid_in_sync),
    .ready_rx(sync_ready),
    .valid_out(valid_out_sync),
     /* [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight, // Max correlation value */
    .bit_offset(sync_offset),
    .rotation(sync_rot)
  );

task apply_rotation(input logic signed [7:0] pair_1, input logic signed [7:0] pair2, 
  input logic [1:0] rot, output logic signed [ 7:0] soft_out_0, output logic signed [7:0] soft_out_1);
    unique case (rot)
      P_0: begin
        soft_out_0 = pair_1;
        soft_out_1 = pair2;
      end
      P_90: begin
        soft_out_0 = pair2;
        soft_out_1 = -pair_1;
      end
      P_180: begin
        soft_out_0 = -pair_1;
        soft_out_1 = -pair2;
      end
      P_270: begin
        soft_out_0 = -pair2;
        soft_out_1 = pair_1;
      end
    endcase
  endtask
  

  logic [$clog2(BITS_PER_FRAME*NUM_FRAMES)-1:0] addr;
  logic signed [7:0] din_w;
  logic signed [7:0] dout;
  logic wea;
  logic bram_del_count;
  logic signed [7:0] pair_1_store;
  logic signed [7:0] pair_2_store;
  logic first_inp_read;
  logic [1:0] final_count;
  logic last_delay;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(BITS_PER_FRAME*NUM_FRAMES),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) store_inp (
    .addra(addr),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(),   // Port B address bus, width determined from RAM_DEPTH
    .dina(din_w),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(),     // Port B clock
    .wea(wea),       // Port A write enable
    .web(),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b0),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b0), // Port B output register enable
    .douta(dout),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
  );

  always_ff @(posedge clk) begin
    if (rst_in) begin
      inp_count <= 0;
      state <= IDLE;
      valid_in_sync <= 0;
      wea <= 0;
    end else begin
      unique case (state)
        IDLE: begin
          valid_in_sync <= 0;
          final_count <= 0;
          valid_out <= 0;
          wea <= 0;
          first_inp_read <= 1;
          if (sync_ready) begin
            state <= READ;
            inp_count <= 0;
            ready_in <= 1;
            addr <= 0;
          end else begin
            ready_in <= 0;
          end
        end
        READ: begin
          if (valid_in ) begin
            // If going to input all the values
            if (inp_count == BITS_PER_FRAME * NUM_FRAMES - 1) begin
              state <= WAIT_SYNC;
              ready_in <= 0;
            end 
            inp_count <= inp_count + 1;
            valid_in_sync <= 1;
            hard_inp <= ~soft_inp[INPUT_SIZE-1];
            // Write the value to the BRAM 
            // TODO: Issue is here: just writing to the second addr
            if (first_inp_read) begin
              first_inp_read <= 0;
            end else begin
            addr <= addr + 1;
            end
            din_w <= soft_inp;
            wea <= 1;
          end
        end
        WAIT_SYNC: begin
          wea <= 0;
          valid_in_sync <= 0;
          if (valid_out_sync) begin
            state <= OUT_READ1;
            rot <= sync_rot;
            offset <= sync_offset;
            addr <= sync_offset;
          end
        end
        OUT_READ1: begin
          // TODO: Start reading if READY_TX
          if (ready_tx) begin
            addr <= addr + 1;
            state <= OUT_READ2;
            valid_out <= 0;
          end 
          // Derotate
          // Transition back to IDLE
          // Reset vars
        end
        OUT_READ2: begin
          // TODO: Start reading if READY_TX
          if (ready_tx) begin
            addr <= addr + 1;
            state <= OUT_COMP;
            bram_del_count <= 0;
            final_count <= 0;
          end else begin
            addr <= addr - 1;
            state <= OUT_READ1;
          end
        end
        OUT_COMP: begin
          if (!ready_tx) begin
            if (final_count != 0) begin
              state <= OUT_LAST;
              final_count <= final_count - 1;
              if (final_count == 2) begin
                pair_1_store <= dout;
              end else if (final_count == 1) begin
                pair_2_store <= dout;
              end
            end else  begin
              state <= OUT_READ1;
              final_count <= 0; // here
              valid_out <= 0;
              addr <= (bram_del_count) ? addr - 3: addr - 2;
            end
          end else  begin
            if (addr == BITS_PER_FRAME * NUM_FRAMES - 1) begin
              final_count <= 2;
              addr <= 0;
            end else begin
              addr <= addr + 1;
            end
            
            if (final_count == 2) begin
              final_count <= 1;
            end else if (final_count == 1) begin
              addr <= 0;
              final_count <= 0;
              state <= IDLE;
            end

            bram_del_count <= ~bram_del_count;
            if (!bram_del_count) begin
              valid_out <= 0;
              pair_1_store <= dout;
            end else begin
              valid_out <= 1;
              apply_rotation(pair_1_store, dout, rot, soft_out_0, soft_out_1);
            end
          end
        end
        OUT_LAST: begin
          if (!ready_tx) begin
            if (final_count == 1) begin
              pair_2_store <= dout;
              final_count <= 0;
            end
          end else begin
            valid_out <= 1;
            state <= IDLE;
            apply_rotation(pair_1_store, (final_count == 1) ? dout : pair_2_store, rot, soft_out_0,
              soft_out_1);
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire

