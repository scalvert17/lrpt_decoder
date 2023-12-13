`timescale 1ns / 1ps
`default_nettype none

// TODO: Remove the top 8 bits
module conv_deinterleaver #(
  parameter NUM_INP = 128, // Input is 128, 8 bit values
  parameter INPUT_SIZE = 8, // Each reading is 8 bit vaule
  parameter BRANCH_COUNT = 36,
  parameter BRANCH_DELAY = 2048
)(
  input wire clk,
  input wire sys_rst,
  input wire signed [7:0] input_soft_0,
  input wire signed [7:0] input_soft_1,
  input vaild_in,
  input first_data,
  input last_data,
  input ready_out_s,

  output ready_in,
  output valid_out,
  output logic signed [7:0] deint_out,
  

  //DDR 3 ports
  inout   wire    [15:0]  ddr3_dq,
  inout   wire    [1:0]   ddr3_dqs_n,
  inout   wire    [1:0]   ddr3_dqs_p,
  output  wire    [12:0]  ddr3_addr,
  output  wire    [2:0]   ddr3_ba,
  output  wire            ddr3_ras_n,
  output  wire            ddr3_cas_n,
  output  wire            ddr3_we_n,
  output  wire            ddr3_reset_n,
  output  wire            ddr3_ck_p,
  output  wire            ddr3_ck_n,
  output  wire            ddr3_cke,
  output  wire    [1:0]   ddr3_dm,
  output  wire            ddr3_odt

  );
   
  // user interface signals
  logic [26:0]      app_addr;
  logic [2:0]       app_cmd;
  logic             app_en;
  logic [127:0]     app_wdf_data;
  logic             app_wdf_end;
  logic             app_wdf_wren;
  logic [127:0]     app_rd_data;
  logic           app_rd_data_end;
  logic           app_rd_data_valid;
  logic           app_rdy;
  logic           app_wdf_rdy;
  logic           app_sr_req;
  logic           app_ref_req;
  logic           app_zq_req;
  logic           app_sr_active;
  logic           app_ref_ack;
  logic           app_zq_ack;
  logic           ui_clk;
  logic           ui_clk_sync_rst;
  logic [15:0]    app_wdf_mask;
  logic           init_calib_complete;
  logic [11:0]    device_temp;

  wire clk_100, clk_200;
  ddr3_clk ddr3_clk_inst (
    .clk_100(clk_100),
    .clk_200(clk_200),
    .clk_in1(clk)
  );

  logic sys_rst_200, sys_rst_200_0, sys_rst_200_1;
  always_ff @(posedge clk_200) begin
    sys_rst_200_0 <= sys_rst;
    sys_rst_200_1 <= sys_rst_200_0;
    sys_rst_200 <= sys_rst_200_1;
  end

  ddr3_mig ddr3_mig_inst (
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .sys_clk_i(clk_200),
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy), 
    .app_sr_req(app_sr_req),
    .app_ref_req(app_ref_req),
    .app_zq_req(app_zq_req),
    .app_sr_active(app_sr_active),
    .app_ref_ack(app_ref_ack),
    .app_zq_ack(app_zq_ack),
    .ui_clk(ui_clk), 
    .ui_clk_sync_rst(ui_clk_sync_rst),
    .app_wdf_mask(app_wdf_mask),
    .init_calib_complete(init_calib_complete),
    .device_temp(device_temp),
    .sys_rst(!sys_rst_200) // active low
  );


  logic clk_8125;
  logic clk_out;
  logic locked;

  logic [7:0] fifo_soft_inp_i;
  logic wr_en_inp;
  logic full_inp;
  logic a_full_inp;

  logic [7:0] fifo_soft_inp_o;
  logic r_en_inp;
  logic empty_inp;
   
  m_axis_data_fifo_v2_0_10_top #(
    .C_FIFO_DEPTH(2048),
    .C_IS_ACLK_ASYNC(1)
  ) inp_fifo (
    .rst(sys_rst),
    .wr_clk(clk),
    .din(fifo_soft_inp_i),
    .wr_en(wr_en_inp),
    .full(full_inp),
    .almost_full(a_full_inp),
    .rd_clk(clk_8125),
    .dout(fifo_soft_inp_0),
    .rd_en(r_en_inp),
    .empty(empty_inp)
  );

  logic [7:0] fifo_soft_out_i;
  logic wr_en_out;
  logic full_out;
  logic a_full_out;

  logic [7:0] fifo_soft_out_o;
  logic r_en_out;
  logic empty_out;

  m_axis_data_fifo_v2_0_10_top #(
    .C_FIFO_DEPTH(2048),
    .C_IS_ACLK_ASYNC(1)
  ) out_fifo (
    .rst(sys_rst),
    .wr_clk(clk),
    .din(fifo_soft_out_i),
    .wr_en(wr_en_out),
    .full(full_out),
    .almost_full(a_full_out),
    .rd_clk(clk_8125),
    .dout(fifo_soft_out_o),
    .rd_en(r_en_out),
    .empty(empty_out)
  );
   

  /* clk_wiz_0 mig_clk */
  /*  ( */
  /*   // Clock out ports */
  /*   .clk_out1(clk_out),     // output clk_out1 */
  /*   // Status and control signals */
  /*   .reset(sys_rst), // input reset */
  /*   .locked(locked),       // output locked */
  /*  // Clock in ports */
  /*   .clk_in1(clk)      // input clk_in1 */
  /* ); */

  /* assign clk_8125 = clk_out & locked; */
  typedef enum {
    IDLE = 0,
    READ_IN = 1,
    WAIT_OUT = 2
  } inp_state;

  inp_state state;
  logic signed [7:0] inp_q_hold;
  logic hold_inp_q;
  logic last_data_0;

  // Begin state, then should transition to 
  always_ff @(posedge clk) begin
    // Initial 
    // Then read in if both fifos are empty (Should make both fifos 36Kb)
    if (sys_rst) begin
      wr_en_inp <= 0;
      hold_inp_q <= 0;
    end else begin
      unique case (state)
        IDLE: begin
          ready_in <= 1;
          if (valid_in) begin
            inp_q_hold <= soft_out_1;
            state <= READ_IN;
            last_data_0 <= 0;
            hold_inp_q <= 1;
            ready_in <= 0; // Need cycle to serialize inp
            // TODO: Write the 0th value to the fifo buffer
          end
        end
        READ_IN: begin
          if (hold_inp_q) begin
            if (last_data_0) begin
              last_data_0 <= 0;
              state <= WAIT_OUT;
              ready_in <= 0;
            end else begin 
              ready_in <= 1;
            end
            hold_inp_q <= 0;
            // TODO: Write the 1st value to the fifo buffer 
          end else begin
            if (valid_in) begin
              ready_in <= 0;
              hold_inp_q <= 1;
              inp_q_hold <= soft_out_1;
              //TODO: Wrte the 0th valu to fifo
              if (last_data) begin
                last_data_0 <= 1;
              end
            end 
          end
        end
        WAIT_OUT: begin
          if (empty_inp && empty_out) begin
            state <= IDLE;
          end
        end
      endcase
    end
  end
  
  // Should be for output of the last fifo
  always_ff @(posedge clk) begin
    if (sys_rst) begin
      valid_out <= 0;
    end else if (ready_out_s && not empty_out) begin
      // Gonna want to use the read_out 
    end 
  end

  // Gonna want to do the other 
  

endmodule

`default_nettype wire

