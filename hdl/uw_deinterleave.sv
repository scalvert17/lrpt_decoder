`default_nettype none
`timescale 1ns/1ps


/*
* This module recieves as input 8 bit soft I/Q data, performs correlation with a set of 
* synchronization words and outputs frames of interleaved data. Each frame is 80 bits including the 
* 8 bit UW. Every two bytes has an I 8-bit word, followed by an 8-bit Q word 
* 
* Expects valid_in to be high for BITS_PER_FRAME * NUM_FRAMES cycles. 
* After these cycles valid_in should be asserted low until uw_deinterleave outputs ready_rx high
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
  output logic state_out,
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset,
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight,
  output logic [3:0] rotation, 

  // Debugging
  output logic [$clog2(NUM_FRAMES)-1:0] frame_ctr [3:0],
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr [3:0],
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr [3:0],
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr [3:0],
  output logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt [3:0],
  output logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out [3:0],
  output logic wea_b [3:0],
  output logic [2:0] corr_count [3:0],
  output logic hard_inp_int [3:0],
  output logic valid_out_rot_1,
  output logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind_rot_1,
  output logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max_rot_1
);

  // logic state_out;
  localparam [0:31] SYNC_WORDS = 32'h274ED8B1;  // sync words {8'h27, 8'h4E, 8'hD8, 8'hB1}

  typedef enum  {  
    IDLE = 0,
    READ = 1,
    COMPUTE = 2
  } uw_sync_int_state;

  logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind_store [3:0];
  logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max_store [3:0];

  assign state_out = state;

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
      // offset_weight_max_store[0] <= 0;
      // max_offset_ind_store <= 0;
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
          // Getting errors in with icarus. Manual unroll
          // for (int i = 0; i < 4; i = i + 1) begin
          //   max_offset_ind_store[i] <= rotations[i].max_offset_ind;
          //   offset_weight_max_store[i] <= rotations[i].offset_weight_max;
          // end 
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
        .max_offset_weight(offset_weight_max),

        .frame_ctr(frame_ctr[i]),
        .offset_ctr(offset_ctr[i]),
        .offset_read_addr(offset_read_addr[i]),
        .offset_write_addr(offset_write_addr[i]),
        .write_wgt(write_wgt[i]),
        .read_wgt_out(read_wgt_out[i]),
        .wea_b(wea_b[i]),
        .corr_count(corr_count[i])
      );
    end
  endgenerate

  // logic valid_out_rot_1;
  // logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind_rot_1;
  // logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max_rot_1;

  // logic [$clog2(NUM_FRAMES)-1:0] frame_ctr [3:0];
  // logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr [3:0];
  // logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr [3:0];
  // logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt [3:0];
  // logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out [3:0];
  // logic wea_b [3:0];
  // logic [2:0] corr_count [3:0];
  // logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr [3:0];
  // logic hard_inp_int [3:0];
  // logic prev_valid_in [3:0];

  assign valid_out_rot_1 = rotations[0].valid_out;
  assign max_offset_ind_rot_1 = rotations[0].max_offset_ind;
  assign offset_weight_max_rot_1 = rotations[0].offset_weight_max;
  
endmodule 

/*
* Once valid_in is high, the correlator expects 80 * 32 input bits. Once all 32 frames have been 
* read, it calculates and output the offset with the highest correlation value, so that this offset
*d is available on the next cycle. 
*/
module uw_sync_derotate_int #(
  parameter BITS_PER_FRAME = 80, // Hard decision
  parameter NUM_FRAMES = 32, // 32 frames each 80 bytes 
  parameter MAX_CORR_VAL = (8 * 32) + 1 , // Each offset correlated against a byte
  parameter logic [7:0] SYNC_WORD = 8'h27
) (
  input wire clk,
  input wire rst_in,
  input wire hard_inp,
  input wire valid_in, 


  output logic valid_out, 
  output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset,
  output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight,

  // Debugging 
  
  output logic [$clog2(NUM_FRAMES)-1:0] frame_ctr,
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr,
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr,
  output logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt,
  output logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out,
  output logic wea_b,
  output logic [2:0] corr_count,
  output logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr

);


  logic hard_inp_int;

  typedef enum  {
    IDLE = 0,
    READ = 1
  } uw_sync_derotate_int_state;

  uw_sync_derotate_int_state state;

  logic prev_valid_in;
  always_ff @(posedge clk) begin
    prev_valid_in <= valid_in;
  end


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
          correlators[0].valid_in_corr <= 1;
        end
      end else if (state == READ) begin
        // state <= (valid_in) ? READ : IDLE;
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
            // 3'd7: correlators[7].valid_in_corr <= 1;
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
              // correlators[0].valid_in_corr <= 1;
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
            3'd0: begin
              write_wgt <= correlators[0].new_weight;
            end
            3'd1: begin
              write_wgt <= correlators[1].new_weight;
            end
            3'd2: begin
              write_wgt <= correlators[2].new_weight;
            end
            3'd3: begin
              write_wgt <= correlators[3].new_weight;
            end
            3'd4: begin
              write_wgt <= correlators[4].new_weight;
            end
            3'd5: begin
              write_wgt <= correlators[5].new_weight;
            end
            3'd6: begin
              write_wgt <= correlators[6].new_weight;
            end
            3'd7: begin
              write_wgt <= correlators[7].new_weight;
            end
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

// /*
// * correlator expects 80 * 32 input bits. Once all 32 frames have been read, it calculates and output
// * the offset with the highest correlation value, so that this offset is available on the next cycle
// */
// module uw_sync_derotate_int #(
//   parameter BITS_PER_FRAME = 80, // Hard decision
//   parameter NUM_FRAMES = 32, // 32 frames each 80 bytes 
//   parameter MAX_CORR_VAL = (8 * 32) + 1 , // Each offset correlated against a byte
//   parameter logic [7:0] SYNC_WORD = 8'h27
// ) (
//   input wire clk,
//   input wire rst_in,
//   input wire hard_inp,
//   input wire valid_in, 

//   // Debugging 
//   output logic [$clog2(NUM_FRAMES)-1:0] frame_ctr,
//   output logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr,
//   output logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_addr,
//   output logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr_int,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] write_wgt,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] read_wgt_out,
//   output logic wea_b,
//   output logic [2:0] corr_count,
//   output logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr,
//   output logic hard_inp_int,
//   output logic [7:0] valid_out_corr,
//   output logic state_out,
//   output logic [7:0] valid_in_corr_out,
//   output logic debug_0_write_flag,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] new_weight_out [7:0],
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_0,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_1,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_2,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_3,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_4,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_5,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_6,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] weight_check_7,


//   output logic valid_out, 
//   output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset,
//   output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight

// );

//   typedef enum  {
//     IDLE = 0,
//     READ = 1
//   } uw_sync_derotate_int_state;

//   uw_sync_derotate_int_state state;

//   initial begin
//     state = IDLE;
//     valid_out = 0;
//   end

//   assign state_out = state;

//   assign weight_check_0 = correlators[0].new_weight;
//   assign weight_check_1 = correlators[1].new_weight;
//   assign weight_check_2 = correlators[2].new_weight;
//   assign weight_check_3 = correlators[3].new_weight;
//   assign weight_check_4 = correlators[4].new_weight;
//   assign weight_check_5 = correlators[5].new_weight;
//   assign weight_check_6 = correlators[6].new_weight;
//   assign weight_check_7 = correlators[7].new_weight;


//   // // logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_addr_int;
//   // always_ff @(posedge clk) begin
//   //   offset_write_addr <= offset_write_addr_int;
//   // end


//   always_ff @(posedge clk) begin
//     hard_inp_int <= hard_inp;
//   end

//   always_ff @(posedge clk) begin
//     if (rst_in) begin
//       state <= IDLE;
//       valid_out <= 0;
//       frame_ctr <= 0;
//       offset_ctr <= 0;
//       corr_count <= 0;
//       valid_out <= 0;
//       offset_write_addr <= 0;
//       offset_read_addr <= 0;
//       wea_b <= 0;
//       write_wgt <= 0;
//     end else begin 
//       if (state == IDLE) begin
//         if (valid_in) begin
//           state <= READ;
//           frame_ctr <= 0;
//           offset_ctr <= 0;
//           corr_count <= 0;
//           valid_out <= 0;
//           offset_write_addr <= 0;
//           offset_read_addr <= 0;
//           wea_b <= 0;
//           correlators[0].valid_in_corr <= 1;
//           write_wgt <= 0;
//         end
//       end else if (state == READ) begin
//         state <= (valid_in) ? READ : IDLE;
//         // Proceed 
//         offset_ctr <= (offset_ctr == BITS_PER_FRAME - 1) ? 0 : offset_ctr + 1;
//         corr_count <= corr_count + 1;
//         valid_out <= ((frame_ctr == NUM_FRAMES - 1) && (offset_ctr == BITS_PER_FRAME - 1)) ? 1 : 0;
//         wea_b <= (frame_ctr == 0 && offset_ctr < 8) ? 0 : 1;
//         frame_ctr <= (offset_ctr == BITS_PER_FRAME - 1) ? frame_ctr + 1: frame_ctr;
//         if (offset_read_addr == BITS_PER_FRAME -1) begin 
//           offset_read_addr <= 0;
//         end else begin
//           offset_read_addr <= (frame_ctr == 0 && offset_ctr < BITS_PER_FRAME - 2) ?
//                               0 : offset_read_addr + 1;
//         end

//         if (frame_ctr == 0) begin
//           // Starting the correlators
//           case (corr_count) 
//             3'd0: correlators[1].valid_in_corr <= 1; 
//             3'd1: correlators[2].valid_in_corr <= 1;
//             3'd2: correlators[3].valid_in_corr <= 1;
//             3'd3: correlators[4].valid_in_corr <= 1;
//             3'd4: correlators[5].valid_in_corr <= 1;
//             3'd5: correlators[6].valid_in_corr <= 1;
//             3'd6: correlators[7].valid_in_corr <= 1;
//             // 3'd7: correlators[7].valid_in_corr <= 1;
//           endcase
//         end else if (frame_ctr == NUM_FRAMES - 1 && offset_ctr >= BITS_PER_FRAME - 8) begin
//           case (corr_count)
//             3'd0: correlators[0].valid_in_corr <= 0;
//             3'd1: correlators[1].valid_in_corr <= 0;
//             3'd2: correlators[2].valid_in_corr <= 0;
//             3'd3: correlators[3].valid_in_corr <= 0;
//             3'd4: correlators[4].valid_in_corr <= 0;
//             3'd5: correlators[5].valid_in_corr <= 0;
//             3'd6: correlators[6].valid_in_corr <= 0;
//             3'd7: begin 
//               write_wgt <= 0;
//               correlators[0].valid_in_corr <= 1;
//               correlators[7].valid_in_corr <= 0;
//             end
//             //TODO: maybe add some stuff here __^ 
//           endcase
//         end

//         // Write 

//         if (frame_ctr == 0 && offset_ctr >= 8 || frame_ctr != 0) begin
//           if (offset_ctr > 8 || frame_ctr != 0 ) begin
//             offset_write_addr <= (offset_write_addr == BITS_PER_FRAME - 1) ? 0 : offset_write_addr + 1;
//           end
//           if (write_wgt > max_offset_weight) begin
//             bit_offset <= offset_write_addr;
//             max_offset_weight <= write_wgt;
//           end
//           case (corr_count) 
//             3'd0: begin
//               write_wgt <= correlators[0].new_weight;
//               // if (correlators[0].new_weight > max_offset_weight) begin
//               //   debug_0_write_flag <= 1;
//               //   // bit_offset <= offset_write_addr;
//               //   bit_offset <= 0;
//               //   max_offset_weight <= correlators[0].new_weight;
//               // end
//             end
//             3'd1: begin
//               write_wgt <= correlators[1].new_weight;
//               // if (correlators[1].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[1].new_weight;
//               // end
//             end
//             3'd2: begin
//               write_wgt <= correlators[2].new_weight;
//               // if (correlators[2].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[2].new_weight;
//               // end
//             end
//             3'd3: begin
//               write_wgt <= correlators[3].new_weight;
//               // if (correlators[3].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[3].new_weight;
//               // end
//             end
//             3'd4: begin
//               write_wgt <= correlators[4].new_weight;
//               // if (correlators[4].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[4].new_weight;
//               // end
//             end
//             3'd5: begin
//               write_wgt <= correlators[5].new_weight;
//               // if (correlators[5].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[5].new_weight;
//               // end
//             end
//             3'd6: begin
//               write_wgt <= correlators[6].new_weight;
//               // if (correlators[6].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[6].new_weight;
//               // end
//             end
//             3'd7: begin
//               write_wgt <= correlators[7].new_weight;
//               // if (correlators[7].new_weight > max_offset_weight) begin
//               //   bit_offset <= offset_write_addr;
//               //   max_offset_weight <= correlators[7].new_weight;
//               // end
//             end
//           endcase
//         end else begin
//           max_offset_weight <= 0;
//           offset_write_addr <= 0;
//         end
//       end 
//     end
//   end


//   assign new_weight_out[0] = correlators[0].new_weight;
//   assign new_weight_out[1] = correlators[1].new_weight;
//   assign new_weight_out[2] = correlators[2].new_weight;
//   assign new_weight_out[3] = correlators[3].new_weight;
//   assign new_weight_out[4] = correlators[4].new_weight;
//   assign new_weight_out[5] = correlators[5].new_weight;
//   assign new_weight_out[6] = correlators[6].new_weight;
//   assign new_weight_out[7] = correlators[7].new_weight;

//   assign valid_in_corr_out[0] = correlators[0].valid_in_corr;
//   assign valid_in_corr_out[1] = correlators[1].valid_in_corr;
//   assign valid_in_corr_out[2] = correlators[2].valid_in_corr;
//   assign valid_in_corr_out[3] = correlators[3].valid_in_corr;
//   assign valid_in_corr_out[4] = correlators[4].valid_in_corr;
//   assign valid_in_corr_out[5] = correlators[5].valid_in_corr;
//   assign valid_in_corr_out[6] = correlators[6].valid_in_corr;
//   assign valid_in_corr_out[7] = correlators[7].valid_in_corr;


//   generate 
//     genvar i;
//     for (i=0; i<8; i=i+1) begin: correlators
//       logic valid_in_corr;
//       // logic valid_out_corr;
//       logic [$clog2(MAX_CORR_VAL)-1:0] new_weight;
//       correlator #(
//         .SYNC_WORD(SYNC_WORD),
//         .MAX_CORR_VAL(MAX_CORR_VAL))
//       correlate (
//           .clk(clk),
//           .sys_rst(rst_in),
//           .inp_bit(hard_inp_int),
//           .past_weight((frame_ctr != 0)? read_wgt_out : 0),
//           .valid_in(valid_in_corr),
//           .valid_out(valid_out_corr[i]),
//           .new_weight(new_weight)
//         );
//       end
//   endgenerate


//   xilinx_true_dual_port_read_first_2_clock_ram #(
//     .RAM_WIDTH($clog2(MAX_CORR_VAL)),
//     .RAM_DEPTH(BITS_PER_FRAME))
//     offset_weights (
//     .addra(offset_read_addr),
//     .clka(clk),
//     .wea(1'b0),
//     .dina(),
//     .ena(1'b1),
//     .regcea(1'b1),
//     .rsta(rst_in),
//     .douta(read_wgt_out),
//     .addrb(offset_write_addr),
//     .dinb(write_wgt),
//     .clkb(clk),
//     .web(wea_b),
//     .enb(1'b1),
//     .rstb(rst_in),
//     .regceb(1'b1),
//     .doutb()
//   );
  
// endmodule


/*
* correlator expects a continuos stream of data. If stream is interrupted coorrelation begins
* with sum from past_weight
*/
module correlator #(
  parameter logic [7:0] SYNC_WORD = 8'h27,
  parameter MAX_CORR_VAL = (8 * 32) + 1,
  parameter SIZE_OF_CONV = 8
)(
  input wire clk,
  input wire sys_rst,
  input wire inp_bit,
  input wire [$clog2(MAX_CORR_VAL)-1:0] past_weight, // Reads on each 
  input wire valid_in, 

  output logic valid_out,
  output logic [$clog2(MAX_CORR_VAL)-1:0] new_weight
  // output logic corr_bit
);
  logic [2:0] counter;

  initial begin
    valid_out = 0;
    counter = 0;
  end
  
  // assign corr_bit = inp_bit ^ SYNC_WORD[SIZE_OF_CONV-counter-1];


  always_ff @(posedge clk) begin
    if (sys_rst) begin
      counter <= 0;
      valid_out <= 0;
      new_weight <= 0;
    end else if (valid_in) begin
      // new_weight <= ((counter == 0) ? past_weight : new_weight) 
      //                                 + (SYNC_WORD[SIZE_OF_CONV-counter-1] ~^ inp_bit);

      new_weight <= ((counter == 0) ? past_weight : new_weight) 
                                      + $unsigned(SYNC_WORD[SIZE_OF_CONV-counter-1] ~^ inp_bit);
      valid_out <= (counter == 7) ? 1 : 0;
      counter <= counter + 1;

    end else begin
      counter <= 0;
      new_weight <= 0;
    end
  end
endmodule

`default_nettype wire



//  logic [$clog2(BITS_PER_FRAME)-1:0] max_offset_ind;
//   logic [3:0] max_rotation;
//   logic [$clog2(MAX_CORR_VAL)-1:0] offset_weight_max;
//   logic max_valid; // Flag for valid offset max

//   logic [$clog2(NUM_FRAMES)-1:0] frame_ctr;
//   logic [$clog2(BITS_PER_FRAME)-1:0] offset_ctr;
//   logic [$clog2(BITS_PER_FRAME)-1:0] offset_read_ctr;
//   logic [$clog2(BITS_PER_FRAME)-1:0] offset_write_ctr;
//   logic [$clog2(MAX_CORR_VAL)-1:0] dinb [3:0];
//   logic [$clog2(MAX_CORR_VAL)-1:0] read_out [3:0];
//   logic wea_b;

//   logic [$clog2(MAX_CORR_VAL)-1:0] past_weight [3:0];
//   logic [7:0] conv_count;
  
//   generate 
//     genvar i, j;
//     for(i=0; i<8; i=i+1) begin: correlators
//       logic valid_in_conv;
//       logic valid_out_conv [3:0];
//       logic [$clog2(MAX_CORR_VAL)-1:0] new_weights [3:0];
//       for (j=0; j<4; j = j + 1) begin: rotation
//         correlator #(
//           .SYNC_WORD(SYNC_WORDS[j*8 +: 8]),
//           .MAX_CORR_VAL(MAX_CORR_VAL))
//         convolve (
//           .clk(clk),
//           .sys_rst(rst_in),
//           .inp_bit(hard_inp),
//           .past_weight(past_weight[j]),
//           .valid_in(valid_in_conv),
//           .valid_out(valid_out_conv[j]),
//           .new_weight(new_weights[j])
//         );
//       end
//     end
//   endgenerate

//   always_ff @(posedge clk) begin
//     if (rst_in) begin
//       max_offset_ind <= 0;
//       max_valid <= 0;
//       bit_offset <= 0;
//     end else begin
//       case (state)
//         IDLE: begin
//           if (!ready_in || !valid_in) begin
//             ready_in <= 1;
//           end
//           if (valid_in) begin
//             state <= READ;
//             offset_ctr <= offset_ctr + 1;
//             conv_count <= conv_count + 1;


//           end else begin
//             offset_ctr <= 0;
//             offset_read_ctr <= 0;
//             offset_write_ctr <= 0;
//             frame_ctr <= 0;
//             conv_count <= 0;
//             past_weight <= 0;
            
//           end
//           wea_b <= 0;
//         end
//       endcase
//     end
    
    
//     else if (valid_in) begin
//       // READ offset read_ctr according to some conditions
//       // Then feed into correlators the new input 
//       // Initialze another correlator with the output of read two cycles ago 
//       // Increment offset_weight max and write to the bram the result of last correlator. 
//       offset_ctr <= offset_ctr + 1;
//       conv_count <= conv_count + 1;
//       wea_b <= (frame_ctr == 0 && offset_ctr < 8) ? 0 : 1;


//       if ((frame_ctr == 0 && offset_ctr >= 8) || frame_ctr != 0) begin
//         // Write to buffer addr_b 
//         offset_write_ctr <= offset_write_ctr + 1;
//         for (int i = 0; i < 4; i = i + 1) begin
//           case (conv_count) 
//             8'd0: dinb[i] <= correlators[0].new_weights[i];
//             8'd1: dinb[i] <= correlators[1].new_weights[i];
//             8'd2: dinb[i] <= correlators[2].new_weights[i];
//             8'd3: dinb[i] <= correlators[3].new_weights[i];
//             8'd4: dinb[i] <= correlators[4].new_weights[i];
//             8'd5: dinb[i] <= correlators[5].new_weights[i];
//             8'd6: dinb[i] <= correlators[6].new_weights[i];
//             8'd7: dinb[i] <= correlators[7].new_weights[i];
//           endcase
//         end
//         case (conv_count) 
//           8'd0: begin
//             if (correlators[0].new_weights[0] > offset_weight_max &&
//               correlators[0].new_weights[0] > correlators[0].new_weights[1] &&
//               correlators[0].new_weights[0] > correlators[0].new_weights[2] &&
//               correlators[0].new_weights[0] > correlators[0].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[0].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[0].new_weights[1] > offset_weight_max &&
//               correlators[0].new_weights[1] > correlators[0].new_weights[0] &&
//               correlators[0].new_weights[1] > correlators[0].new_weights[2] &&  
//               correlators[0].new_weights[1] > correlators[0].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[0].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[0].new_weights[2] > offset_weight_max &&
//               correlators[0].new_weights[2] > correlators[0].new_weights[1] &&
//               correlators[0].new_weights[2] > correlators[0].new_weights[0] &&
//               correlators[0].new_weights[2] > correlators[0].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[0].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[0].new_weights[3] > offset_weight_max &&
//               correlators[0].new_weights[3] > correlators[0].new_weights[1] &&
//               correlators[0].new_weights[3] > correlators[0].new_weights[0] && 
//               correlators[0].new_weights[3] > correlators[0].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[0].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd1: begin
//             if (correlators[1].new_weights[0] > offset_weight_max &&
//               correlators[1].new_weights[0] > correlators[1].new_weights[1] &&
//               correlators[1].new_weights[0] > correlators[1].new_weights[2] &&
//               correlators[1].new_weights[0] > correlators[1].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[1].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[1].new_weights[1] > offset_weight_max &&
//               correlators[1].new_weights[1] > correlators[1].new_weights[0] &&
//               correlators[1].new_weights[1] > correlators[1].new_weights[2] &&  
//               correlators[1].new_weights[1] > correlators[1].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[1].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[1].new_weights[2] > offset_weight_max &&
//               correlators[1].new_weights[2] > correlators[1].new_weights[1] &&
//               correlators[1].new_weights[2] > correlators[1].new_weights[0] &&
//               correlators[1].new_weights[2] > correlators[1].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[1].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[1].new_weights[3] > offset_weight_max &&
//               correlators[1].new_weights[3] > correlators[1].new_weights[1] &&
//               correlators[1].new_weights[3] > correlators[1].new_weights[0] && 
//               correlators[1].new_weights[3] > correlators[1].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[1].new_weights[3];
//               max_rotation <= 3;
//             end
//           end           
//           8'd2: begin
//             if (correlators[2].new_weights[0] > offset_weight_max &&
//               correlators[2].new_weights[0] > correlators[2].new_weights[1] &&
//               correlators[2].new_weights[0] > correlators[2].new_weights[2] &&
//               correlators[2].new_weights[0] > correlators[2].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[2].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[2].new_weights[1] > offset_weight_max &&
//               correlators[2].new_weights[1] > correlators[2].new_weights[0] &&
//               correlators[2].new_weights[1] > correlators[2].new_weights[2] &&  
//               correlators[2].new_weights[1] > correlators[2].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[2].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[2].new_weights[2] > offset_weight_max &&
//               correlators[2].new_weights[2] > correlators[2].new_weights[1] &&
//               correlators[2].new_weights[2] > correlators[2].new_weights[0] &&
//               correlators[2].new_weights[2] > correlators[2].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[2].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[2].new_weights[3] > offset_weight_max &&
//               correlators[2].new_weights[3] > correlators[2].new_weights[1] &&
//               correlators[2].new_weights[3] > correlators[2].new_weights[0] && 
//               correlators[2].new_weights[3] > correlators[2].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[2].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd3: begin
//             if (correlators[3].new_weights[0] > offset_weight_max &&
//               correlators[3].new_weights[0] > correlators[3].new_weights[1] &&
//               correlators[3].new_weights[0] > correlators[3].new_weights[2] &&
//               correlators[3].new_weights[0] > correlators[3].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[3].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[3].new_weights[1] > offset_weight_max &&
//               correlators[3].new_weights[1] > correlators[3].new_weights[0] &&
//               correlators[3].new_weights[1] > correlators[3].new_weights[2] &&  
//               correlators[3].new_weights[1] > correlators[3].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[3].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[3].new_weights[2] > offset_weight_max &&
//               correlators[3].new_weights[2] > correlators[3].new_weights[1] &&
//               correlators[3].new_weights[2] > correlators[3].new_weights[0] &&
//               correlators[3].new_weights[2] > correlators[3].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[3].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[3].new_weights[3] > offset_weight_max &&
//               correlators[3].new_weights[3] > correlators[3].new_weights[1] &&
//               correlators[3].new_weights[3] > correlators[3].new_weights[0] && 
//               correlators[3].new_weights[3] > correlators[3].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[3].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd4: begin
//             if (correlators[4].new_weights[0] > offset_weight_max &&
//               correlators[4].new_weights[0] > correlators[4].new_weights[1] &&
//               correlators[4].new_weights[0] > correlators[4].new_weights[2] &&
//               correlators[4].new_weights[0] > correlators[4].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[4].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[4].new_weights[1] > offset_weight_max &&
//               correlators[4].new_weights[1] > correlators[4].new_weights[0] &&
//               correlators[4].new_weights[1] > correlators[4].new_weights[2] &&  
//               correlators[4].new_weights[1] > correlators[4].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[4].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[4].new_weights[2] > offset_weight_max &&
//               correlators[4].new_weights[2] > correlators[4].new_weights[1] &&
//               correlators[4].new_weights[2] > correlators[4].new_weights[0] &&
//               correlators[4].new_weights[2] > correlators[4].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[4].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[4].new_weights[3] > offset_weight_max &&
//               correlators[4].new_weights[3] > correlators[4].new_weights[1] &&
//               correlators[4].new_weights[3] > correlators[4].new_weights[0] && 
//               correlators[4].new_weights[3] > correlators[4].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[4].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd5: begin
//             if (correlators[5].new_weights[0] > offset_weight_max &&
//               correlators[5].new_weights[0] > correlators[5].new_weights[1] &&
//               correlators[5].new_weights[0] > correlators[5].new_weights[2] &&
//               correlators[5].new_weights[0] > correlators[5].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[5].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[5].new_weights[1] > offset_weight_max &&
//               correlators[5].new_weights[1] > correlators[5].new_weights[0] &&
//               correlators[5].new_weights[1] > correlators[5].new_weights[2] &&  
//               correlators[5].new_weights[1] > correlators[5].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[5].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[5].new_weights[2] > offset_weight_max &&
//               correlators[5].new_weights[2] > correlators[5].new_weights[1] &&
//               correlators[5].new_weights[2] > correlators[5].new_weights[0] &&
//               correlators[5].new_weights[2] > correlators[5].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[5].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[5].new_weights[3] > offset_weight_max &&
//               correlators[5].new_weights[3] > correlators[5].new_weights[1] &&
//               correlators[5].new_weights[3] > correlators[5].new_weights[0] && 
//               correlators[5].new_weights[3] > correlators[5].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[5].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd6: begin
//             if (correlators[6].new_weights[0] > offset_weight_max &&
//               correlators[6].new_weights[0] > correlators[6].new_weights[1] &&
//               correlators[6].new_weights[0] > correlators[6].new_weights[2] &&
//               correlators[6].new_weights[0] > correlators[6].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[6].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[6].new_weights[1] > offset_weight_max &&
//               correlators[6].new_weights[1] > correlators[6].new_weights[0] &&
//               correlators[6].new_weights[1] > correlators[6].new_weights[2] &&  
//               correlators[6].new_weights[1] > correlators[6].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[6].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[6].new_weights[2] > offset_weight_max &&
//               correlators[6].new_weights[2] > correlators[6].new_weights[1] &&
//               correlators[6].new_weights[2] > correlators[6].new_weights[0] &&
//               correlators[6].new_weights[2] > correlators[6].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[6].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[6].new_weights[3] > offset_weight_max &&
//               correlators[6].new_weights[3] > correlators[6].new_weights[1] &&
//               correlators[6].new_weights[3] > correlators[6].new_weights[0] && 
//               correlators[6].new_weights[3] > correlators[6].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[6].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//           8'd7: begin
//             if (correlators[7].new_weights[0] > offset_weight_max &&
//               correlators[7].new_weights[0] > correlators[7].new_weights[1] &&
//               correlators[7].new_weights[0] > correlators[7].new_weights[2] &&
//               correlators[7].new_weights[0] > correlators[7].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[7].new_weights[0];
//               max_rotation <= 0;
//             end else if (correlators[7].new_weights[1] > offset_weight_max &&
//               correlators[7].new_weights[1] > correlators[7].new_weights[0] &&
//               correlators[7].new_weights[1] > correlators[7].new_weights[2] &&  
//               correlators[7].new_weights[1] > correlators[7].new_weights[3] 
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[7].new_weights[1];
//               max_rotation <= 1;
//             end else if (correlators[7].new_weights[2] > offset_weight_max &&
//               correlators[7].new_weights[2] > correlators[7].new_weights[1] &&
//               correlators[7].new_weights[2] > correlators[7].new_weights[0] &&
//               correlators[7].new_weights[2] > correlators[7].new_weights[3]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[7].new_weights[2];
//               max_rotation <= 2;
//             end else if (correlators[7].new_weights[3] > offset_weight_max &&
//               correlators[7].new_weights[3] > correlators[7].new_weights[1] &&
//               correlators[7].new_weights[3] > correlators[7].new_weights[0] && 
//               correlators[7].new_weights[3] > correlators[7].new_weights[2]
//             ) begin
//               max_offset_ind <= offset_write_ctr;
//               offset_weight_max <= correlators[7].new_weights[3];
//               max_rotation <= 3;
//             end
//           end
//         endcase 
//       end

//       if (frame_ctr == 0) begin
//         if (max_valid) begin
//           max_valid <= 0;
//           // TODO: output max_stuff like the bit_offset
//           offset_weight_max <= 0; // Reset max value
//           rotation <= max_rotation;
//           bit_offset <= max_offset_ind;;
//           valid_out <= 1;

//           // for (int i = 1; i < 8; i = i + 1) begin
//           //   correlators[i].valid_in_conv <= 0;
//           // end
//           correlators[0].valid_in_conv <= 0;
//           correlators[1].valid_in_conv <= 0;
//           correlators[2].valid_in_conv <= 0;
//           correlators[3].valid_in_conv <= 0;
//           correlators[4].valid_in_conv <= 0;
//           correlators[5].valid_in_conv <= 0;
//           correlators[6].valid_in_conv <= 0;
//           correlators[7].valid_in_conv <= 0;
//         end else valid_out <= 0;

//         case (conv_count) 
//           8'd0: correlators[0].valid_in_conv <= 1; // Key line here for offsetting 
//           8'd1: correlators[1].valid_in_conv <= 1;
//           8'd2: correlators[2].valid_in_conv <= 1;
//           8'd3: correlators[3].valid_in_conv <= 1;
//           8'd4: correlators[4].valid_in_conv <= 1;
//           8'd5: correlators[5].valid_in_conv <= 1;
//           8'd6: correlators[6].valid_in_conv <= 1;
//           8'd7: correlators[7].valid_in_conv <= 1;
//         endcase
        
//         past_weight[0] <= 0;
//         past_weight[1] <= 0;
//         past_weight[2] <= 0;
//         past_weight[3] <= 0;
        
//         if (offset_ctr >= BITS_PER_FRAME - 2) begin
//           // Start reading from the BRAMs
//           offset_read_ctr <= offset_read_ctr + 1;
//         end
        
//         // init gen at conv_count
//         // write gen value at conv_count to offset - 8 
//         // need another base case for offset < 8
//         // 
//         // Actually backwards
//         // Read 8 new_weight and write. Also read new value for 2 ahead.
//         // Also send new weight that was read 2 cycles ago to 0? 
//         // Work out the bouldary conditinon and stuff before this is started
//         // 7th correlator should update its value, and then output it on the next cycle. So on zero should have the
//         // final output. 
//         // P close 
//       end else begin
//         valid_out <= 0;
//         max_valid <= 1;
//         for (int j = 0; j < 4; j = j + 1) begin
//           past_weight[j] <= read_out[j];
//         end
//         // Write to buffer addr_b 

//         offset_write_ctr <= offset_write_ctr + 1;
//         offset_read_ctr <= offset_read_ctr + 1;

//         if (frame_ctr == 31) begin
//           // 80 - 7 so that last bit in frame is still valid
//           if (offset_ctr >= BITS_PER_FRAME - 7) begin
//             //TODO: conv_count should work here test if not
//             case (conv_count)
//               8'd0: correlators[0].valid_in_conv <= 0;
//               8'd1: correlators[1].valid_in_conv <= 0;
//               8'd2: correlators[2].valid_in_conv <= 0;
//               8'd3: correlators[3].valid_in_conv <= 0;
//               8'd4: correlators[4].valid_in_conv <= 0;
//               8'd5: correlators[5].valid_in_conv <= 0;
//               8'd6: correlators[6].valid_in_conv <= 0;
//               8'd7: correlators[7].valid_in_conv <= 0;
//             endcase
//           end
//         end
//       end
//     end else valid_out <= 0;
//   end

//   generate 
//     genvar k;
//     for (k = 0; k < 4; k = k + 1) begin 
//       xilinx_true_dual_port_read_first_2_clock_ram #(
//         .RAM_WIDTH(MAX_CORR_VAL),
//         .RAM_DEPTH(BITS_PER_FRAME))
//         offset_weights (
//         .addra(offset_read_ctr),
//         .clka(clk),
//         .wea(1'b0),
//         .dina(),
//         .ena(1'b1),
//         .regcea(1'b1),
//         .rsta(rst_in),
//         .douta(read_out[k]),
//         .addrb(offset_write_ctr),
//         .dinb(dinb[k]),
//         .clkb(clk),
//         .web(wea_b),
//         .enb(1'b1),
//         .rstb(rst_in),
//         .regceb(1'b1),
//         .doutb()
//       );
//     end
//   endgenerate