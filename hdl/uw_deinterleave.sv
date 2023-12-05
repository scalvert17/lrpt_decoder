`default_nettype none
`timescale 1ns/1ps


/*
* This module recieves as input hard I/Q data, performs correlation with a set of 
* synchronization words and outputs frames of interleaved data. Each frame is 80 bits including the 
* 8 bit UW. Every two bytes has an I 8-bit word, followed by an 8-bit Q word 
* 
* Expects valid_in to be high for BITS_PER_FRAME * NUM_FRAMES cycles.  
* After these cycles valid_in must be asserted low until uw_deinterleave outputs ready_rx high
*/
module uw_deinterleave #(
  parameter BITS_PER_FRAME = 80, // Hard decision
  parameter MAX_CORR_VAL = (8 * 32) + 1, // Each offset correlated against a byte
  parameter NUM_FRAMES = 32 // 32 frames each 80 bytes 
) (
  input wire clk,
  input wire rst_in,
  input wire hard_inp,
  input wire valid_in, 

  output logic ready_rx,
  output logic valid_out, 
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset, // Offset of the max correlation
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight, // Max correlation value
  output logic [3:0] rotation // Rotation of the max correlation


);
  localparam [0:31] SYNC_WORDS = 32'h274ED8B1;  // sync words {8'h27, 8'h4E, 8'hD8, 8'hB1}

  typedef enum  {  
    IDLE = 0,
    READ = 1,
    COMPUTE = 2
  } uw_sync_int_state;

  logic [$clog2(NUM_FRAMES)-1:0] frame_ctr [3:0];
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr [3:0];
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr [3:0];
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr [3:0];
  logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt [3:0];
  logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out [3:0];
  logic wea_b [3:0];
  logic [2:0] corr_count [3:0];
  logic hard_inp_int [3:0];

  logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind_store [3:0];
  logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max_store [3:0];

  uw_sync_int_state state;

  logic prev_valid_in;
  logic prev_hard_inp;
  logic prev_hard_inp1;
  logic rst_in_alt;
  logic valid_in_back;
  logic valid_in_back_2;

  always_ff @(posedge clk) begin
    prev_hard_inp1 <= hard_inp;
    prev_hard_inp <= prev_hard_inp1;
    valid_in_back <= valid_in;
  end


  always_ff @(posedge clk) begin
    if (rst_in) begin
      state <= IDLE;
      valid_out <= 0;
      for (int i = 0; i < 4; i = i + 1) begin
        max_offset_ind_store[i] <= 0;
        offset_weight_max_store[i] <= 0;
      end
    end else begin
      if (state == IDLE) begin
        ready_rx <= 1;
        prev_valid_in <= 0;
        if (valid_in) begin
          rst_in_alt <= 1;
          state <= READ;
        end else begin
          rst_in_alt <= 1;
        end
      end else if (state == READ) begin
        valid_out <= 0;
        prev_valid_in <= 1;
        rst_in_alt <= 0;
        if (rotations[0].valid_out) begin // Check if the correlators are done
          ready_rx <= 0;
          prev_valid_in <= 0;
          state <= COMPUTE;
          max_offset_ind_store[0] <= rotations[0].max_offset_ind;
          offset_weight_max_store[0] <= rotations[0].offset_weight_max;
          max_offset_ind_store[1] <= rotations[1].max_offset_ind;
          offset_weight_max_store[1] <= rotations[1].offset_weight_max;
          max_offset_ind_store[2] <= rotations[2].max_offset_ind;
          offset_weight_max_store[2] <= rotations[2].offset_weight_max;
          max_offset_ind_store[3] <= rotations[3].max_offset_ind;
          offset_weight_max_store[3] <= rotations[3].offset_weight_max;
        end else begin
          ready_rx <= 1;
        end
      end else if (state == COMPUTE) begin
        // Compute the maxes 
        valid_out <= 1;
        state <= IDLE;
        // Compute maxes
        if (offset_weight_max_store[0] > offset_weight_max_store[1] &&
            offset_weight_max_store[0] > offset_weight_max_store[2] &&
            offset_weight_max_store[0] > offset_weight_max_store[3] ) begin
          bit_offset <= max_offset_ind_store[0];
          rotation <= 0;
          max_offset_weight <= offset_weight_max_store[0];
        end else if (offset_weight_max_store[1] > offset_weight_max_store[0] &&
            offset_weight_max_store[1] > offset_weight_max_store[2] &&
            offset_weight_max_store[1] > offset_weight_max_store[3] ) begin
          bit_offset <= max_offset_ind_store[1];
          rotation <= 1;
          max_offset_weight <= offset_weight_max_store[1];
        end else if (offset_weight_max_store[2] > offset_weight_max_store[1] &&
            offset_weight_max_store[2] > offset_weight_max_store[3] &&
            offset_weight_max_store[2] > offset_weight_max_store[0] ) begin
          bit_offset <= max_offset_ind_store[2];
          rotation <= 2;
          max_offset_weight <= offset_weight_max_store[2];
        end else begin
          bit_offset <= max_offset_ind_store[3];
          rotation <= 3;
          max_offset_weight <= offset_weight_max_store[3];
        end
      end
    end
  end

  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin: rotations 
      logic valid_out;
      logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind;
      logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max;

      uw_sync_derotate_int #(
        .BITS_PER_FRAME(BITS_PER_FRAME),
        .NUM_FRAMES(NUM_FRAMES),
        .MAX_CORR_VAL(MAX_CORR_VAL),
        .SYNC_WORD(SYNC_WORDS[i*8 +: 8]))
      uw_sync_rotate (
        .clk(clk),
        .rst_in(rst_in || rst_in_alt),
        .hard_inp(prev_hard_inp),
        .valid_in((valid_in || valid_in_back) && (state == READ) && prev_valid_in ),
        .valid_out(valid_out),
        .bit_offset(max_offset_ind),
        .max_offset_weight(offset_weight_max)
      );
    end
  endgenerate
endmodule 

/*
* Once valid_in is high, the correlator expects 80 * 32 input bits. Once all 32 frames have been 
* read, it calculates and output the offset with the highest correlation value, so that this offset
*d is available on the next cycle. 
*/
module uw_sync_derotate_int #(
  parameter BITS_PER_FRAME = 80, // Hard decision bits
  parameter NUM_FRAMES = 32, // 32 frames each 80 bits hard decision
  parameter MAX_CORR_VAL = (8 * 32) + 1 , // Each offset correlated against a byte
  parameter logic [7:0] SYNC_WORD = 8'h27
) (
  input wire clk,
  input wire rst_in,
  input wire hard_inp, 
  input wire valid_in,
  output logic valid_out,
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset,
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight
);

  logic hard_inp_int;
  logic [$clog2(NUM_FRAMES)-1:0] frame_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr;
  logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt;
  logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out;
  logic wea_b;
  logic [2:0] corr_count;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr;


  typedef enum  {
    IDLE = 0,
    READ = 1
  } uw_sync_derotate_int_state;

  uw_sync_derotate_int_state state;

  always_ff @(posedge clk) begin
    if (rst_in) begin
      state <= IDLE;
      valid_out <= 0;
      frame_ctr <= 0;
      offset_ctr <= 0;
      corr_count <= 0;
      valid_out <= 0;
      offset_write_addr <= 0;
      offset_read_addr <= 0;
      wea_b <= 0;
      write_wgt <= 0;
      bit_offset <= 0;
    end else begin 
      hard_inp_int <= hard_inp;
      if (state == IDLE) begin
        valid_out <= 0;
        max_offset_weight <= 0;
        bit_offset <= 0;
        frame_ctr <= 0;
        offset_ctr <= 0;
        corr_count <= 0;
        valid_out <= 0;
        offset_write_addr <= 0;
        offset_read_addr <= 0;
        wea_b <= 0;
        write_wgt <= 0;
        if (valid_in) begin
          state <= READ;
          correlators[0].valid_in_corr <= 1; // Initialize the first correlator 
        end
      end else if (state == READ) begin
        // Proceed 
        offset_ctr <= (offset_ctr == BITS_PER_FRAME - 1) ? 0 : offset_ctr + 1;
        corr_count <= corr_count + 1;
        valid_out <= ((frame_ctr == NUM_FRAMES - 1) && (offset_ctr == BITS_PER_FRAME - 1)) ? 1 : 0;
        wea_b <= (frame_ctr == 0 && offset_ctr < 8) ? 0 : 1;
        frame_ctr <= (offset_ctr == BITS_PER_FRAME - 1) ? frame_ctr + 1: frame_ctr;
        if (offset_read_addr == BITS_PER_FRAME -1) begin 
          offset_read_addr <= 0;
        end else begin
          offset_read_addr <= (frame_ctr == 0 && offset_ctr < BITS_PER_FRAME - 2) ?
                              0 : offset_read_addr + 1;
        end

        if (frame_ctr == 0) begin
          // Starting the correlators
          case (corr_count) 
            3'd0: correlators[1].valid_in_corr <= 1; 
            3'd1: correlators[2].valid_in_corr <= 1;
            3'd2: correlators[3].valid_in_corr <= 1;
            3'd3: correlators[4].valid_in_corr <= 1;
            3'd4: correlators[5].valid_in_corr <= 1;
            3'd5: correlators[6].valid_in_corr <= 1;
            3'd6: correlators[7].valid_in_corr <= 1;
          endcase
        end else if (frame_ctr == NUM_FRAMES - 1 && offset_ctr >= BITS_PER_FRAME - 8) begin
          case (corr_count)
            3'd0: correlators[0].valid_in_corr <= 0;
            3'd1: correlators[1].valid_in_corr <= 0;
            3'd2: correlators[2].valid_in_corr <= 0;
            3'd3: correlators[3].valid_in_corr <= 0;
            3'd4: correlators[4].valid_in_corr <= 0;
            3'd5: correlators[5].valid_in_corr <= 0;
            3'd6: correlators[6].valid_in_corr <= 0;
            3'd7: begin 
              write_wgt <= 0;
              correlators[7].valid_in_corr <= 0;
              state <= IDLE;
            end
          endcase
        end

        // Write 
        if (frame_ctr == 0 && offset_ctr >= 8 || frame_ctr != 0) begin
          if (offset_ctr > 8 || frame_ctr != 0 ) begin
            offset_write_addr <= (offset_write_addr == BITS_PER_FRAME - 1) ? 0 : offset_write_addr + 1;
          end
          if (write_wgt > max_offset_weight) begin
            bit_offset <= offset_write_addr;
            max_offset_weight <= write_wgt;
          end
          case (corr_count) 
            3'd0: write_wgt <= correlators[0].new_weight;
            3'd1: write_wgt <= correlators[1].new_weight;
            3'd2: write_wgt <= correlators[2].new_weight;
            3'd3: write_wgt <= correlators[3].new_weight;
            3'd4: write_wgt <= correlators[4].new_weight;
            3'd5: write_wgt <= correlators[5].new_weight;
            3'd6: write_wgt <= correlators[6].new_weight;
            3'd7: write_wgt <= correlators[7].new_weight;
          endcase
        end else begin
          max_offset_weight <= 0;
          offset_write_addr <= 0;
        end
      end 
    end
  end


  generate 
    genvar i;
    for (i=0; i<8; i=i+1) begin: correlators
      logic valid_in_corr;
      logic valid_out_corr;
      logic [$clog2(MAX_CORR_VAL)-1:0] new_weight;
      correlator #(
        .SYNC_WORD(SYNC_WORD),
        .MAX_CORR_VAL(MAX_CORR_VAL))
      correlate (
          .clk(clk),
          .sys_rst(rst_in),
          .inp_bit(hard_inp_int),
          .past_weight((frame_ctr != 0)? read_wgt_out : 0),
          .valid_in(valid_in_corr),
          .valid_out(valid_out_corr),
          .new_weight(new_weight)
        );
      end
  endgenerate


  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH($clog2(MAX_CORR_VAL)),
    .RAM_DEPTH(BITS_PER_FRAME))
    offset_weights (
    .addra(offset_read_addr),
    .clka(clk),
    .wea(1'b0),
    .dina(),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(read_wgt_out),
    .addrb(offset_write_addr),
    .dinb(write_wgt),
    .clkb(clk),
    .web(wea_b),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb()
  );
  
endmodule

/*
* correlator expects a continuos stream of data. If stream is interrupted coorrelation begins
* with sum from new_input weight
*/
module correlator #(
  parameter logic [SIZE_OF_CONV-1:0] SYNC_WORD = 8'h27,
  parameter MAX_CORR_VAL = (8 * 32) + 1,
  parameter SIZE_OF_CONV = 8
)(
  input wire clk,
  input wire sys_rst,
  input wire inp_bit,
  input wire [$clog2(MAX_CORR_VAL)-1:0] past_weight, // Input to correlator
  input wire valid_in, 

  output logic valid_out,
  output logic [$clog2(MAX_CORR_VAL)-1:0] new_weight // Output of past_weight and correlation
);

  logic [$clog2(SIZE_OF_CONV)-1:0] counter;

  always_ff @(posedge clk) begin
    if (sys_rst) begin
      counter <= 0;
      valid_out <= 0;
      new_weight <= 0;
    end else if (valid_in) begin
      new_weight <= ((counter == 0) ? past_weight : new_weight) 
                                      + $unsigned(SYNC_WORD[SIZE_OF_CONV-counter-1] ~^ inp_bit);
      valid_out <= (counter == SIZE_OF_CONV - 1) ? 1 : 0;
      counter <= (counter == SIZE_OF_CONV - 1) ? 0 : counter + 1;

    end else begin
      counter <= 0;
      new_weight <= 0;
    end
  end
endmodule

`default_nettype wire

