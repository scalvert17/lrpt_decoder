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

  // logic [35:0] dout_debug_tbu;
  // assign dout_debug_tbu = dout_0[0];
  // logic [35:0] din_debug_tbu;
  // assign din_debug_tbu = din_w[0];
  logic [$clog2(S)-1:0] addr_0_debug_tbu;
  assign addr_0_debug_tbu = addr_0_r[0];
  logic [$clog2(S)-1:0] addr_0_r_see_if_it_pass;
  logic [$clog2(S)-1:0] addr_1_r_see_if_it_pass;

  logic [$clog2(S)-1:0] addr_1_r [15:0];
  logic [35:0] din_1_r [15:0];
  logic [35:0] dout_1 [15:0];
  logic desc_out_1;
  logic val_out_r_1;


  logic [$clog2(S)-1:0] addr_w; // [15:0];
  logic [35:0] din_w [15:0];
  logic wea ;//[15:0];

  read_ptr #(
    .IND_START(60)
  ) read_ptr_0 (
    .clk(clk),
    .sys_rst(sys_rst),
    .write_index(addr_w),
    .valid_in(valid_in),
    .addr(addr_0_r),
    .dout(dout_0),
    .desc_out(desc_out_0),
    .addr_0_r_see_if_it_pass(addr_0_r_see_if_it_pass),
    .valid_out(val_out_r_0)
  );

  read_ptr #(
    .IND_START(30)
  ) read_ptr_1 (
    .clk(clk),
    .sys_rst(sys_rst),
    .write_index(addr_w),
    .valid_in(valid_in),
    .addr(addr_1_r),
    .dout(dout_1),
    .desc_out(desc_out_1),
    .addr_0_r_see_if_it_pass(addr_1_r_see_if_it_pass),  
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
        .dina(din_0_r[i]),     // Port A RAM input data, width determined from RAM_WIDTH
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
        .dina(din_1_r[i]),     // Port A RAM input data, width determined from RAM_WIDTH
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
  input wire [35:0] dout [15:0],
  output logic desc_out,
  output logic valid_out,
  output logic [$clog2(S)-1:0] addr_0_r_see_if_it_pass,
  output logic [$clog2(S)-1:0] addr [15:0]
);

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

  assign addr_0_r_see_if_it_pass = addr[0];


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
            // for (int i = 0; i < 16; i = i + 1) begin
            //   addr[i] <= col_ind;
            // end
            addr[0] <= col_ind;
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

