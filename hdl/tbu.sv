`timescale 1ns / 1ps
`default_nettype none

/*
* 
*/
// TODO: We need to use K = 2 now to avoid the issue with multi driven nets as different read ptrs may try accesing the 
// same bram on the same cycle. So gonna have to either generate two setns of BRAMS.  HUHU
module tbu (
  input wire clk,
  input wire sys_rst,
  input wire [5:0] prev_state [NUM_STATES-1:0],
  input wire desc [NUM_STATES-1:0],
  //! Store as {desc, prev_state}. The top 8 bits should only be padding 
  input wire valid_in, // Should be high at most once for any two consecutive cycles 
  output logic vit_desc,
  output logic valid_out
);

  localparam K = 2;// Number of read ptrs
  localparam NUM_STATES = 64;
  localparam S = 120; // Number of trellis stages to store
  localparam X_MIN = 30; // Min number of stages to traceback st survivor path merge 
  localparam B = 30; // Read ptr traces back X_min stages and reads out B values 


  logic [$clog2(S)-1:0] addr_0_r [15:0];
  logic [35:0] din_0_r [15:0];
  logic [35:0] dout_0 [15:0];
  logic desc_out_0;
  logic val_out_r_0;

  logic [$clog2(S)-1:0] addr_1_r [15:0];
  logic [35:0] din_1_r [15:0];
  logic [35:0] dout_1 [15:0];
  logic desc_out_1;
  logic val_out_r_1;


  logic [$clog2(S)-1:0] addr_w; // [15:0];
  logic [35:0] din_w [15:0];
  logic wea ;//[15:0];

  // TODO: Please fix this 
  // Probabaly just helps iverilog
  logic [5:0] prev_state_0;
  assign prev_state_0 = prev_state[0];

  logic [$clog2(S)-1:0] addr_0_r_0;
  logic [$clog2(S)-1:0] addr_0_r_1;
  logic [$clog2(S)-1:0] addr_0_r_2;
  logic [$clog2(S)-1:0] addr_0_r_3;
  logic [$clog2(S)-1:0] addr_0_r_4;
  logic [$clog2(S)-1:0] addr_0_r_5;
  logic [$clog2(S)-1:0] addr_0_r_6;
  logic [$clog2(S)-1:0] addr_0_r_7;
  logic [$clog2(S)-1:0] addr_0_r_8;
  logic [$clog2(S)-1:0] addr_0_r_9;
  logic [$clog2(S)-1:0] addr_0_r_10;
  logic [$clog2(S)-1:0] addr_0_r_11;
  logic [$clog2(S)-1:0] addr_0_r_12;
  logic [$clog2(S)-1:0] addr_0_r_13;
  logic [$clog2(S)-1:0] addr_0_r_14;
  logic [$clog2(S)-1:0] addr_0_r_15;
  assign addr_0_r[0] = addr_0_r_0;
  assign addr_0_r[1] = addr_0_r_1;
  assign addr_0_r[2] = addr_0_r_2;
  assign addr_0_r[3] = addr_0_r_3;
  assign addr_0_r[4] = addr_0_r_4;
  assign addr_0_r[5] = addr_0_r_5;
  assign addr_0_r[6] = addr_0_r_6;
  assign addr_0_r[7] = addr_0_r_7;
  assign addr_0_r[8] = addr_0_r_8;
  assign addr_0_r[9] = addr_0_r_9;
  assign addr_0_r[10] = addr_0_r_10;
  assign addr_0_r[11] = addr_0_r_11;
  assign addr_0_r[12] = addr_0_r_12;
  assign addr_0_r[13] = addr_0_r_13;
  assign addr_0_r[14] = addr_0_r_14;
  assign addr_0_r[15] = addr_0_r_15;

  logic [35:0] dout_0_0;
  logic [35:0] dout_0_1;
  logic [35:0] dout_0_2;
  logic [35:0] dout_0_3;
  logic [35:0] dout_0_4;
  logic [35:0] dout_0_5;
  logic [35:0] dout_0_6;
  logic [35:0] dout_0_7;
  logic [35:0] dout_0_8;
  logic [35:0] dout_0_9;
  logic [35:0] dout_0_10;
  logic [35:0] dout_0_11;
  logic [35:0] dout_0_12;
  logic [35:0] dout_0_13;
  logic [35:0] dout_0_14;
  logic [35:0] dout_0_15;

  assign dout_0_0 = dout_0[0];
  assign dout_0_1 = dout_0[1];
  assign dout_0_2 = dout_0[2];
  assign dout_0_3 = dout_0[3];
  assign dout_0_4 = dout_0[4];
  assign dout_0_5 = dout_0[5];
  assign dout_0_6 = dout_0[6];
  assign dout_0_7 = dout_0[7];
  assign dout_0_8 = dout_0[8];
  assign dout_0_9 = dout_0[9];
  assign dout_0_10 = dout_0[10];
  assign dout_0_11 = dout_0[11];
  assign dout_0_12 = dout_0[12];
  assign dout_0_13 = dout_0[13];
  assign dout_0_14 = dout_0[14];
  assign dout_0_15 = dout_0[15];

  logic [$clog2(S)-1:0] addr_1_r_0;
  logic [$clog2(S)-1:0] addr_1_r_1;
  logic [$clog2(S)-1:0] addr_1_r_2;
  logic [$clog2(S)-1:0] addr_1_r_3;
  logic [$clog2(S)-1:0] addr_1_r_4;
  logic [$clog2(S)-1:0] addr_1_r_5;
  logic [$clog2(S)-1:0] addr_1_r_6;
  logic [$clog2(S)-1:0] addr_1_r_7;
  logic [$clog2(S)-1:0] addr_1_r_8;
  logic [$clog2(S)-1:0] addr_1_r_9;
  logic [$clog2(S)-1:0] addr_1_r_10;
  logic [$clog2(S)-1:0] addr_1_r_11;
  logic [$clog2(S)-1:0] addr_1_r_12;
  logic [$clog2(S)-1:0] addr_1_r_13;
  logic [$clog2(S)-1:0] addr_1_r_14;
  logic [$clog2(S)-1:0] addr_1_r_15;
  assign addr_1_r[0] = addr_1_r_0;
  assign addr_1_r[1] = addr_1_r_1;
  assign addr_1_r[2] = addr_1_r_2;
  assign addr_1_r[3] = addr_1_r_3;
  assign addr_1_r[4] = addr_1_r_4;
  assign addr_1_r[5] = addr_1_r_5;
  assign addr_1_r[6] = addr_1_r_6;
  assign addr_1_r[7] = addr_1_r_7;
  assign addr_1_r[8] = addr_1_r_8;
  assign addr_1_r[9] = addr_1_r_9;
  assign addr_1_r[10] = addr_1_r_10;
  assign addr_1_r[11] = addr_1_r_11;
  assign addr_1_r[12] = addr_1_r_12;
  assign addr_1_r[13] = addr_1_r_13;
  assign addr_1_r[14] = addr_1_r_14;
  assign addr_1_r[15] = addr_1_r_15;

  logic [35:0] dout_1_0;
  logic [35:0] dout_1_1;
  logic [35:0] dout_1_2;
  logic [35:0] dout_1_3;
  logic [35:0] dout_1_4;
  logic [35:0] dout_1_5;
  logic [35:0] dout_1_6;
  logic [35:0] dout_1_7;
  logic [35:0] dout_1_8;
  logic [35:0] dout_1_9;
  logic [35:0] dout_1_10;
  logic [35:0] dout_1_11;
  logic [35:0] dout_1_12;
  logic [35:0] dout_1_13;
  logic [35:0] dout_1_14;
  logic [35:0] dout_1_15;
  assign dout_1_0 = dout_1[0];
  assign dout_1_1 = dout_1[1];
  assign dout_1_2 = dout_1[2];
  assign dout_1_3 = dout_1[3];
  assign dout_1_4 = dout_1[4];
  assign dout_1_5 = dout_1[5];
  assign dout_1_6 = dout_1[6];
  assign dout_1_7 = dout_1[7];
  assign dout_1_8 = dout_1[8];
  assign dout_1_9 = dout_1[9];
  assign dout_1_10 = dout_1[10];
  assign dout_1_11 = dout_1[11];
  assign dout_1_12 = dout_1[12];
  assign dout_1_13 = dout_1[13];
  assign dout_1_14 = dout_1[14];
  assign dout_1_15 = dout_1[15];




  read_ptr #(
    .IND_START(60)
  ) read_ptr_0 (
    .clk(clk),
    .sys_rst(sys_rst),
    .write_index(addr_w),
    .valid_in(valid_in),
    // .addr(addr_0_r),
    // .dout(dout_0),
    .addr_0(addr_0_r_0),
    .addr_1(addr_0_r_1),
    .addr_2(addr_0_r_2),
    .addr_3(addr_0_r_3),
    .addr_4(addr_0_r_4),
    .addr_5(addr_0_r_5),
    .addr_6(addr_0_r_6),
    .addr_7(addr_0_r_7),
    .addr_8(addr_0_r_8),
    .addr_9(addr_0_r_9),
    .addr_10(addr_0_r_10),
    .addr_11(addr_0_r_11),
    .addr_12(addr_0_r_12),
    .addr_13(addr_0_r_13),
    .addr_14(addr_0_r_14),
    .addr_15(addr_0_r_15),
    .dout_0(dout_0_0),
    .dout_1(dout_0_1),
    .dout_2(dout_0_2),
    .dout_3(dout_0_3),
    .dout_4(dout_0_4),
    .dout_5(dout_0_5),
    .dout_6(dout_0_6),
    .dout_7(dout_0_7),
    .dout_8(dout_0_8),
    .dout_9(dout_0_9),
    .dout_10(dout_0_10),
    .dout_11(dout_0_11),
    .dout_12(dout_0_12),
    .dout_13(dout_0_13),
    .dout_14(dout_0_14),
    .dout_15(dout_0_15),
    .desc_out(desc_out_0),
    .valid_out(val_out_r_0)
  );

  read_ptr #(
    .IND_START(30)
  ) read_ptr_1 (
    .clk(clk),
    .sys_rst(sys_rst),
    .write_index(addr_w),
    .valid_in(valid_in),
    // .addr(addr_1_r),
    // .dout(dout_1),
    .addr_0(addr_1_r_0),
    .addr_1(addr_1_r_1),
    .addr_2(addr_1_r_2),
    .addr_3(addr_1_r_3),
    .addr_4(addr_1_r_4),
    .addr_5(addr_1_r_5),
    .addr_6(addr_1_r_6),
    .addr_7(addr_1_r_7),
    .addr_8(addr_1_r_8),
    .addr_9(addr_1_r_9),
    .addr_10(addr_1_r_10),
    .addr_11(addr_1_r_11),
    .addr_12(addr_1_r_12),
    .addr_13(addr_1_r_13),
    .addr_14(addr_1_r_14),
    .addr_15(addr_1_r_15),
    .dout_0(dout_1_0),
    .dout_1(dout_1_1),
    .dout_2(dout_1_2),
    .dout_3(dout_1_3),
    .dout_4(dout_1_4),
    .dout_5(dout_1_5),
    .dout_6(dout_1_6),
    .dout_7(dout_1_7),
    .dout_8(dout_1_8),
    .dout_9(dout_1_9),
    .dout_10(dout_1_10),
    .dout_11(dout_1_11),
    .dout_12(dout_1_12),
    .dout_13(dout_1_13),
    .dout_14(dout_1_14),
    .dout_15(dout_1_15),

    .desc_out(desc_out_1),
    .valid_out(val_out_r_1)
  );
  

  generate
    genvar i;
    for (i = 0; i < NUM_STATES / 4; i = i + 1) begin : rows_0
      xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(36),                       // Specify RAM data width
        .RAM_DEPTH(512),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      ) store_row (
        .addra(addr_0_r[i]),   // Port A address bus, width determined from RAM_DEPTH
        .addrb(addr_w),   // Port B address bus, width determined from RAM_DEPTH
        .dina(1'b0),     // Port A RAM input data, width determined from RAM_WIDTH
        .dinb(din_w[i]),     // Port B RAM input data, width determined from RAM_WIDTH
        .clka(clk),     // Port A clock
        .clkb(clk),     // Port B clock
        .wea(1'b0),       // Port A write enable
        .web(wea),       // Port B write enable
        .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
        .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst),     // Port A output reset (does not affect memory contents)
        .rstb(sys_rst),     // Port B output reset (does not affect memory contents)
        .regcea(1'b1), // Port A output register enable
        .regceb(1'b1), // Port B output register enable
        .douta(dout_0[i]),   // Port A RAM output data, width determined from RAM_WIDTH
        .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
      );
    end
    for (i = 0; i < NUM_STATES / 4; i = i + 1) begin : rows_1
      xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(36),                       // Specify RAM data width
        .RAM_DEPTH(512),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      ) store_row (
        .addra(addr_1_r[i]),   // Port A address bus, width determined from RAM_DEPTH
        .addrb(addr_w),   // Port B address bus, width determined from RAM_DEPTH
        .dina(1'b0),     // Port A RAM input data, width determined from RAM_WIDTH
        .dinb(din_w[i]),     // Port B RAM input data, width determined from RAM_WIDTH
        .clka(clk),     // Port A clock
        .clkb(clk),     // Port B clock
        .wea(1'b0),       // Port A write enable
        .web(wea),       // Port B write enable
        .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
        .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst),     // Port A output reset (does not affect memory contents)
        .rstb(sys_rst),     // Port B output reset (does not affect memory contents)
        .regcea(1'b1), // Port A output register enable
        .regceb(1'b1), // Port B output register enable
        .douta(dout_1[i]),   // Port A RAM output data, width determined from RAM_WIDTH
        .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
      );
    end
  endgenerate

  //
  always_ff @(posedge clk) begin
    if (sys_rst) begin 
      valid_out <= 0;
      addr_w <= 0;
      wea <= 0;
 
      // for (int i = 0; i < NUM_STATES / 4; i = i + 1) begin
      //   addr_0_r[i] <= 0;
      // end
      // for (int i = 0; i < NUM_STATES / 4; i = i + 1) begin
      //   addr_1_r[i] <= 0;
      // end

      
    end else begin
      if (valid_in) begin
        // Write to the dual brams
        wea <= 1;
        addr_w <= (addr_w == 0) ? S - 1: addr_w - 1;
        for (int i = 0; i < NUM_STATES / 4; i = i + 1) begin
          din_w[i] <= {8'b0, desc[4*i+3], prev_state[4*i+3], desc[4*i+2], prev_state[4*i+2], 
            desc[4*i+1], prev_state[4*i+1], desc[4*i], prev_state[4*i]};
        end
      end else begin
        wea <= 0;
      end
      // Set the output 
      if (val_out_r_0) begin
        valid_out <= 1;
        vit_desc <= desc_out_0;
      end else if (val_out_r_1) begin
        valid_out <= 1;
        vit_desc <= desc_out_1;
      end else begin
        valid_out <= 0;
      end
    end
  end
endmodule

module read_ptr #(
  parameter B = 30,
  parameter X_MIN = 30,
  parameter IND_START = 30,
  parameter S = 120,
  parameter NUM_STATES = 64
)(
  input wire clk,
  input wire sys_rst,
  input wire [$clog2(S)-1:0] write_index,
  input wire valid_in,
  // input wire [35:0] dout [15:0],
  input wire [35:0] dout_0,
  input wire [35:0] dout_1,
  input wire [35:0] dout_2,
  input wire [35:0] dout_3,
  input wire [35:0] dout_4,
  input wire [35:0] dout_5,
  input wire [35:0] dout_6,
  input wire [35:0] dout_7,
  input wire [35:0] dout_8,
  input wire [35:0] dout_9,
  input wire [35:0] dout_10,
  input wire [35:0] dout_11,
  input wire [35:0] dout_12,
  input wire [35:0] dout_13,
  input wire [35:0] dout_14,
  input wire [35:0] dout_15,
  output logic desc_out,
  output logic valid_out,
  // output logic [$clog2(S)-1:0] addr [15:0]
  output logic [$clog2(S)-1:0] addr_0,
  output logic [$clog2(S)-1:0] addr_1,
  output logic [$clog2(S)-1:0] addr_2,
  output logic [$clog2(S)-1:0] addr_3,
  output logic [$clog2(S)-1:0] addr_4,
  output logic [$clog2(S)-1:0] addr_5,
  output logic [$clog2(S)-1:0] addr_6,
  output logic [$clog2(S)-1:0] addr_7,
  output logic [$clog2(S)-1:0] addr_8,
  output logic [$clog2(S)-1:0] addr_9,
  output logic [$clog2(S)-1:0] addr_10,
  output logic [$clog2(S)-1:0] addr_11,
  output logic [$clog2(S)-1:0] addr_12,
  output logic [$clog2(S)-1:0] addr_13,
  output logic [$clog2(S)-1:0] addr_14,
  output logic [$clog2(S)-1:0] addr_15
);

  logic [35:0] dout [15:0];
  assign dout[0] = dout_0;
  assign dout[1] = dout_1;
  assign dout[2] = dout_2;
  assign dout[3] = dout_3;
  assign dout[4] = dout_4;
  assign dout[5] = dout_5;
  assign dout[6] = dout_6;
  assign dout[7] = dout_7;
  assign dout[8] = dout_8;
  assign dout[9] = dout_9;
  assign dout[10] = dout_10;
  assign dout[11] = dout_11;
  assign dout[12] = dout_12;
  assign dout[13] = dout_13;
  assign dout[14] = dout_14;
  assign dout[15] = dout_15;

  logic [$clog2(S)-1:0] addr [15:0];
  assign addr_0 = addr[0];
  assign addr_1 = addr[1];
  assign addr_2 = addr[2];
  assign addr_3 = addr[3];
  assign addr_4 = addr[4];
  assign addr_5 = addr[5];
  assign addr_6 = addr[6];
  assign addr_7 = addr[7];
  assign addr_8 = addr[8];
  assign addr_9 = addr[9];
  assign addr_10 = addr[10];
  assign addr_11 = addr[11];
  assign addr_12 = addr[12];
  assign addr_13 = addr[13];
  assign addr_14 = addr[14];
  assign addr_15 = addr[15];




  typedef enum {
    IDLE=0, // Should only be idle before the write ptr initially reaches its position
    TRACEBACK=1,
    READ=2
  } read_state;

  read_state state;

  logic [$clog2(S)-1:0] col_ind;
  logic [$clog2(NUM_STATES)-1:0] row_ind;
  logic [$clog2(X_MIN)-1:0] traceback_ctr;
  logic [$clog2(B)-1:0] readback_ctr;

  // Logic for read with longer than 1 cycle for valid in
  logic holding_dout;
  logic [6:0] dout_store;
  logic exp_bram_read;

  initial begin
    col_ind <= IND_START;
    row_ind <= 0;
  end



  always_ff @(posedge clk) begin
    if (sys_rst) begin
      col_ind <= IND_START;
      row_ind <= 0;
      valid_out <= 0;
      exp_bram_read <= 0;
      readback_ctr <= 0;
      traceback_ctr <= 0;
      state <= IDLE; // Need to be reading in IDLE, 
      holding_dout <= 0;
      // for (int i = 0; i < 16; i = i + 1) begin
      //   addr[i] <= 0;
      // end
    end else if (valid_in) begin
      holding_dout <= 0;
      exp_bram_read <= 1;
      case (state)
        IDLE: begin
          valid_out <= 0;
          if (col_ind == write_index) begin
            state <= TRACEBACK;
            col_ind <= (col_ind + 1) % S;
            row_ind <= (holding_dout) ? dout_store[5:0] : dout[0][5:0]; // Prev_state of 0th row
            addr[0] <= (col_ind + 1) % S; // Reading ahead so that prev val and decs are available on the next run;
          end else begin
            for (int i = 0; i < 16; i = i + 1) begin
              addr[i] <= col_ind;
            end
            // addr[0] <= col_ind;

          end
        end
        // For the others going to read the output from the preceding read -> then execute another read and move row
        // based on the output of the read. Remember to use exp_bram_read if necessary.
        TRACEBACK: begin
          // Check if traceback counter maxed out
          valid_out <= 0;
          if (traceback_ctr == X_MIN - 1) begin
            state <= READ;
            traceback_ctr <= 0;
          end else begin 
            traceback_ctr <= traceback_ctr + 1;
          end
          col_ind <= (col_ind + 1) % S;
          // TODO: maybe draw this out into some comb block
          // row_ind <= (holding_dout) ? dout_store[5:0] : (dout[row_ind>>2][7*row_ind[1:0] :+ 7])[5:0]; 
          // if (holding_dout) begin
          //   row_ind <= dout_store[5:0];
          // end else begin
          //   case (row_ind[1:0])
          //     0: row_ind <= (dout[row_ind>>2][6:0])[5:0];
          //     1: row_ind <= (dout[row_ind>>2][13:7])[5:0];
          //     2: row_ind <= (dout[row_ind>>2][20:14])[5:0];
          //     3: row_ind <= (dout[row_ind>>2][27:21])[5:0];
          //   endcase
          // end
          addr[row_ind>>2] <= (col_ind + 1) % S;
        end
        READ: begin
          valid_out <= 1;
          if (readback_ctr == B - 1) begin
            state <= TRACEBACK;
            readback_ctr <= 0;
          end else begin 
            readback_ctr <= readback_ctr + 1;
          end
          col_ind <= (col_ind + 1) % S;
          addr[row_ind>>2] <= (col_ind + 1) % S;
        end
      endcase

      if (state != IDLE) begin
        if (holding_dout) begin
          desc_out <= dout_store[6];
          row_ind <= dout_store[5:0];
        end else begin
          case (row_ind[1:0])
            0: begin
              row_ind <= dout[row_ind>>2][5:0];
              desc_out <= dout[row_ind>>2][6];
            end
            1: begin
              row_ind <= dout[row_ind>>2][12:7];
              desc_out <= dout[row_ind>>2][13];
            end
            2: begin
              row_ind <= dout[row_ind>>2][19:14];
              desc_out <= dout[row_ind>>2][20];
            end
            3: begin
              row_ind <= dout[row_ind>>2][26:21];
              desc_out <= dout[row_ind>>2][27];
            end
          endcase
        end
      end

    end else begin
      valid_out <= 0;
      if (!exp_bram_read) begin
        holding_dout <= 1;
        case (row_ind[1:0])
          0: dout_store <= dout[row_ind>>2][6:0];
          1: dout_store <= dout[row_ind>>2][13:7];
          2: dout_store <= dout[row_ind>>2][20:14];
          3: dout_store <= dout[row_ind>>2][27:21];
        endcase 
        // dout_store <= dout[row_ind >> 2][7 * row_ind[1:0] :+ 7]; 
      end else exp_bram_read <= exp_bram_read - 1;
    end

  end

endmodule

`default_nettype wire

