`default_nettype none
`timescale 1ns/1ps


/*
* This module recieves as input viterbi desicions and performs correlation with the CADU 
* synchronization word: 0x1ACFFC1D. 
* 
* Expects valid_in to be high for BITS_PER_FRAME * NUM_FRAMES cycles.  
* After these cycles valid_in must be asserted low until uw_cadu outputs ready_rx high
*/
module uw_cadu #(
  parameter BITS_PER_FRAME = 1024*8, // 1024 bytes in each CADU
  parameter MAX_CORR_VAL = (32 * 8) + 1, // Operates on 8 CADU frames. 32 bit uw word
  parameter NUM_FRAMES = 8 // CADU frames
) (
  input wire clk,
  input wire rst_in,
  input wire hard_inp,
  input wire valid_in, 

  output logic ready_rx,
  output logic valid_out, 
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset, // Offset of the max correlation
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight // Max correlation value

);
  localparam [31:0] SYNC_WORD = 32'h1ACFFC1D;  
  localparam SIZE_OF_CONV = 32;

  typedef enum  {  
    IDLE = 0,
    READ = 1,
    COMPUTE = 2
  } cadu_sync_int_state;

  logic [$clog2(NUM_FRAMES)-1:0] frame_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr;
  logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt;
  logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out;
  logic wea_b;
  logic [$clog2(SIZE_OF_CONV)-1:0] corr_count; 
  logic hard_inp_int;

  logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind_store;
  logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max_store;

  cadu_sync_int_state state;

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
      max_offset_ind_store <= 0;
      offset_weight_max_store <= 0;
    end else begin
      if (state == IDLE) begin
        valid_out <= 0;
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
          max_offset_ind_store <= rotations[0].max_offset_ind;
          offset_weight_max_store <= rotations[0].offset_weight_max;
        end else begin
          ready_rx <= 1;
        end
      end else if (state == COMPUTE) begin
        // Compute the maxes 
        valid_out <= 1;
        state <= IDLE;
        // Compute maxes
        bit_offset <= max_offset_ind_store;
        max_offset_weight <= offset_weight_max_store;
      end
    end
  end

  generate
    genvar i;
    for (i = 0; i < 1; i = i + 1) begin: rotations 
      logic valid_out;
      logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind;
      logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max;

      cadu_sync_rot #(
        .BITS_PER_FRAME(BITS_PER_FRAME),
        .NUM_FRAMES(NUM_FRAMES),
        .MAX_CORR_VAL(MAX_CORR_VAL),
        .SYNC_WORD(SYNC_WORD))
      cadu_sync_rot (
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
module cadu_sync_rot #(
  parameter BITS_PER_FRAME = 1024*8, // size of CADU packet in bytes 
  parameter NUM_FRAMES = 8, // 32 frames each 80 bits hard decisio
  parameter MAX_CORR_VAL = (8 * 32) + 1 , // Each offset correlated against a byte
  parameter logic [31:0] SYNC_WORD = 32'h1ACFFC1D

) (
  input wire clk,
  input wire rst_in,
  input wire hard_inp, 
  input wire valid_in,
  output logic valid_out,
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset,
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight
);
  localparam SIZE_OF_CONV = 32;

  logic hard_inp_int;
  logic [$clog2(NUM_FRAMES)-1:0] frame_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr;
  logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt;
  logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out;
  logic wea_b;
  logic [$clog2(SIZE_OF_CONV)-1:0] corr_count;
  logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr;


  typedef enum  {
    IDLE = 0,
    READ = 1
  } cadu_sync_derotate_int_state;

  cadu_sync_derotate_int_state state;

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
        wea_b <= (frame_ctr == 0 && offset_ctr < SIZE_OF_CONV) ? 0 : 1;
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
            5'd0: correlators[1].valid_in_corr <= 1; 
            5'd1: correlators[2].valid_in_corr <= 1;
            5'd2: correlators[3].valid_in_corr <= 1;
            5'd3: correlators[4].valid_in_corr <= 1;
            5'd4: correlators[5].valid_in_corr <= 1;
            5'd5: correlators[6].valid_in_corr <= 1;
            5'd6: correlators[7].valid_in_corr <= 1;
            5'd7: correlators[8].valid_in_corr <= 1;
            5'd8: correlators[9].valid_in_corr <= 1;
            5'd9: correlators[10].valid_in_corr <= 1;
            5'd10: correlators[11].valid_in_corr <= 1;
            5'd11: correlators[12].valid_in_corr <= 1;
            5'd12: correlators[13].valid_in_corr <= 1;
            5'd13: correlators[14].valid_in_corr <= 1;
            5'd14: correlators[15].valid_in_corr <= 1;
            5'd15: correlators[16].valid_in_corr <= 1;
            5'd16: correlators[17].valid_in_corr <= 1;
            5'd17: correlators[18].valid_in_corr <= 1;
            5'd18: correlators[19].valid_in_corr <= 1;
            5'd19: correlators[20].valid_in_corr <= 1;
            5'd20: correlators[21].valid_in_corr <= 1;
            5'd21: correlators[22].valid_in_corr <= 1;
            5'd22: correlators[23].valid_in_corr <= 1;
            5'd23: correlators[24].valid_in_corr <= 1;
            5'd24: correlators[25].valid_in_corr <= 1;
            5'd25: correlators[26].valid_in_corr <= 1;
            5'd26: correlators[27].valid_in_corr <= 1;
            5'd27: correlators[28].valid_in_corr <= 1;
            5'd28: correlators[29].valid_in_corr <= 1;
            5'd29: correlators[30].valid_in_corr <= 1;
            5'd30: correlators[31].valid_in_corr <= 1;
          endcase
        end else if (frame_ctr == NUM_FRAMES - 1 && offset_ctr >= BITS_PER_FRAME-SIZE_OF_CONV) begin
          case (corr_count)
            5'd0: correlators[0].valid_in_corr <= 0;
            5'd1: correlators[1].valid_in_corr <= 0;
            5'd2: correlators[2].valid_in_corr <= 0;
            5'd3: correlators[3].valid_in_corr <= 0;
            5'd4: correlators[4].valid_in_corr <= 0;
            5'd5: correlators[5].valid_in_corr <= 0;
            5'd6: correlators[6].valid_in_corr <= 0;
            5'd7: correlators[7].valid_in_corr <= 0;
            5'd8: correlators[8].valid_in_corr <= 0;
            5'd9: correlators[9].valid_in_corr <= 0;
            5'd10: correlators[10].valid_in_corr <= 0;
            5'd11: correlators[11].valid_in_corr <= 0;
            5'd12: correlators[12].valid_in_corr <= 0;
            5'd13: correlators[13].valid_in_corr <= 0;
            5'd14: correlators[14].valid_in_corr <= 0;
            5'd15: correlators[15].valid_in_corr <= 0;
            5'd16: correlators[16].valid_in_corr <= 0;
            5'd17: correlators[17].valid_in_corr <= 0;
            5'd18: correlators[18].valid_in_corr <= 0;
            5'd19: correlators[19].valid_in_corr <= 0;
            5'd20: correlators[20].valid_in_corr <= 0;
            5'd21: correlators[21].valid_in_corr <= 0;
            5'd22: correlators[22].valid_in_corr <= 0;
            5'd23: correlators[23].valid_in_corr <= 0;
            5'd24: correlators[24].valid_in_corr <= 0;
            5'd25: correlators[25].valid_in_corr <= 0;
            5'd26: correlators[26].valid_in_corr <= 0;
            5'd27: correlators[27].valid_in_corr <= 0;
            5'd28: correlators[28].valid_in_corr <= 0;
            5'd29: correlators[29].valid_in_corr <= 0;
            5'd30: correlators[30].valid_in_corr <= 0;
            5'd31: begin 
              write_wgt <= 0;
              correlators[31].valid_in_corr <= 0;
              state <= IDLE;
            end
          endcase
        end

        // Write 
        if (frame_ctr == 0 && offset_ctr >= SIZE_OF_CONV || frame_ctr != 0) begin
          if (offset_ctr > SIZE_OF_CONV || frame_ctr != 0 ) begin
            offset_write_addr <= (offset_write_addr == BITS_PER_FRAME - 1) ? 0 : offset_write_addr + 1;
          end
          if (write_wgt > max_offset_weight) begin
            bit_offset <= offset_write_addr;
            max_offset_weight <= write_wgt;
          end
          case (corr_count) 
            // TODO: add some stuff here
            5'd0: write_wgt <= correlators[0].new_weight;
            5'd1: write_wgt <= correlators[1].new_weight;
            5'd2: write_wgt <= correlators[2].new_weight;
            5'd3: write_wgt <= correlators[3].new_weight;
            5'd4: write_wgt <= correlators[4].new_weight;
            5'd5: write_wgt <= correlators[5].new_weight;
            5'd6: write_wgt <= correlators[6].new_weight;
            5'd7: write_wgt <= correlators[7].new_weight;
            5'd8: write_wgt <= correlators[8].new_weight;
            5'd9: write_wgt <= correlators[9].new_weight;
            5'd10: write_wgt <= correlators[10].new_weight;
            5'd11: write_wgt <= correlators[11].new_weight;
            5'd12: write_wgt <= correlators[12].new_weight;
            5'd13: write_wgt <= correlators[13].new_weight;
            5'd14: write_wgt <= correlators[14].new_weight;
            5'd15: write_wgt <= correlators[15].new_weight;
            5'd16: write_wgt <= correlators[16].new_weight;
            5'd17: write_wgt <= correlators[17].new_weight;
            5'd18: write_wgt <= correlators[18].new_weight;
            5'd19: write_wgt <= correlators[19].new_weight;
            5'd20: write_wgt <= correlators[20].new_weight;
            5'd21: write_wgt <= correlators[21].new_weight;
            5'd22: write_wgt <= correlators[22].new_weight;
            5'd23: write_wgt <= correlators[23].new_weight;
            5'd24: write_wgt <= correlators[24].new_weight;
            5'd25: write_wgt <= correlators[25].new_weight;
            5'd26: write_wgt <= correlators[26].new_weight;
            5'd27: write_wgt <= correlators[27].new_weight;
            5'd28: write_wgt <= correlators[28].new_weight;
            5'd29: write_wgt <= correlators[29].new_weight;
            5'd30: write_wgt <= correlators[30].new_weight;
            5'd31: write_wgt <= correlators[31].new_weight;
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
    for (i=0; i<SIZE_OF_CONV; i=i+1) begin: correlators
      logic valid_in_corr;
      logic valid_out_corr;
      logic [$clog2(MAX_CORR_VAL)-1:0] new_weight;
      correlator #(
        .SYNC_WORD(SYNC_WORD),
        .SIZE_OF_CONV(SIZE_OF_CONV),
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


`default_nettype wire

