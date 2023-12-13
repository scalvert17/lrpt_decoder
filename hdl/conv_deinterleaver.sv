`timescale 1ns / 1ps
`default_nettype none

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
  input ready_out_last,

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

  logic inp_s_valid;
  logic inp_s_ready;
  logic signed [7:0] inp_data_s;

  logic inp_m_valid;
  logic inp_m_ready;
  logic signed [7:0] inp_data_m;
  logic [31:0] inp_read_data_count;

  axis_data_fifo_0 inp_fifo (
    .s_axis_aresetn(sys_rst),          // input wire s_axis_aresetn
    .s_axis_aclk(clk),                // input wire s_axis_aclk
    .s_axis_tvalid(inp_s_valid),            // input wire s_axis_tvalid
    .s_axis_tready(inp_s_ready),            // output wire s_axis_tready
    .s_axis_tdata(inp_data_s),              // input wire [7 : 0] s_axis_tdata
    .m_axis_aclk(ui_clk),                // input wire m_axis_aclk
    .m_axis_tvalid(inp_m_valid),            // output wire m_axis_tvalid
    .m_axis_tready(inp_m_ready),            // input wire m_axis_tready
    .m_axis_tdata(inp_read_data_count)              // output wire [7 : 0] m_axis_tdata
    /* .axis_wr_data_count(axis_wr_data_count),  // output wire [31 : 0] axis_wr_data_count */
    /* .axis_rd_data_count(axis_rd_data_count),  // output wire [31 : 0] axis_rd_data_count */
    /* .almost_empty(almost_empty),              // output wire almost_empty */
    /* .prog_empty(prog_empty),                  // output wire prog_empty */
    /* .almost_full(almost_full),                // output wire almost_full */
    /* .prog_full(prog_full)                    // output wire prog_full */
  );

  logic out_s_valid;
  logic out_s_ready;
  logic signed [7:0] out_data_s;

  logic out_m_valid;
  logic out_m_ready;
  logic signed [7:0] out_data_m;

  logic [31:0] out_write_data_count;

  axis_data_fifo_0 out_fifo (
    .s_axis_aresetn(ui_clk_sync_rst),          // input wire s_axis_aresetn
    .s_axis_aclk(ui_clk),                // input wire s_axis_aclk
    .s_axis_tvalid(out_s_valid),            // input wire s_axis_tvalid
    .s_axis_tready(out_s_ready),            // output wire s_axis_tready
    .s_axis_tdata(out_data_s),              // input wire [7 : 0] s_axis_tdata
    .m_axis_aclk(clk),                // input wire m_axis_aclk
    .m_axis_tvalid(out_m_valid),            // output wire m_axis_tvalid
    .m_axis_tready(out_m_ready),            // input wire m_axis_tready
    .m_axis_tdata(out_data_m),              // output wire [7 : 0] m_axis_tdata
    /* .axis_wr_data_count(axis_wr_data_count),  // output wire [31 : 0] axis_wr_data_count */
    .axis_rd_data_count(out_write_data_count)  // output wire [31 : 0] axis_rd_data_count
    /* .almost_empty(almost_empty),              // output wire almost_empty */
    /* .prog_empty(prog_empty),                  // output wire prog_empty */
    /* .almost_full(almost_full),                // output wire almost_full */
    /* .prog_full(prog_full)                    // output wire prog_full */
  );

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
      inp_s_valid <= 0;
      hold_inp_q <= 0;
    end else begin
      unique case (state)
        IDLE: begin
          if (inp_s_ready && !valid_in) begin
            ready_in <= 1;
          end else begin
            ready_in <= 0;
          end
          if (valid_in) begin
            inp_q_hold <= input_soft_1;
            state <= READ_IN;
            last_data_0 <= 0;
            hold_inp_q <= 1;
            ready_in <= 0; // Need cycle to serialize inp
            inp_s_valid <= 1;
            inp_data_s <= input_soft_0;
          end else begin
            inp_s_valid <= 0;
          end
        end
        READ_IN: begin
          if (hold_inp_q) begin
            if (!inp_s_ready) begin
              inp_s_valid <= 0;
              ready_in <= 0;
            end else begin
              if (last_data_0) begin
                last_data_0 <= 0;
                state <= WAIT_OUT;
                ready_in <= 0;
              end else begin 
                ready_in <= 1;
              end
              inp_s_valid <= 1;
              inp_data_s <= hold_inp_q;
              hold_inp_q <= 0;
            end
          end else begin
            if (valid_in) begin
              ready_in <= 0;
              hold_inp_q <= 1;
              inp_q_hold <= soft_out_1;
              inp_s_valid <= 1;
              inp_data_s <= input_soft_0;
              if (last_data) begin
                last_data_0 <= 1;
              end
            end else begin
              inp_s_valid <= 0;
            end
          end
        end
        WAIT_OUT: begin
          // Maybe go with rd_data_count
          inp_s_valid <= 0;
          ready_in <= 0;
          if (inp_read_data_count == 0 && out_write_data_count == 0) begin
            state <= IDLE;
          end
        end
      endcase
    end
  end

  assign deint_out = out_data_m;
  assign valid_out = out_m_valid;
  assign out_m_ready = ready_out_last;

  typedef enum {
    IDLE_W = 0,
    CALC_DEL = 1,
    CALC_ADDR = 2
  } mig_states;

  // TODO: cite meteor and the MiG from andrew
  //
  mig_states mig_state;
  logic [$clog2(72)-1:0] cur_branch;
  parameter BIG_DEL = 72 * 2048;
  logic [$clog2(BIG_DEL)-1:0] offset;
  logic [$clog2(80*32):0] wr_counter;
  logic sync_mark_count;
  logic signed [7:0] mig_hold_val;
  logic [$clog2(36*36*2048):0] delay;

  // TODO: Logic for interfacing witho MiG and the fifos
  assign app_sr_req = 0;    // We aren't using these signals.
  assign app_ref_req = 0;
  assign app_zq_req = 0;

  always_ff @(posedge ui_clk) begin
    if (ui_clk_sync_rst) begin
      app_addr <= 0;
      sync_mark_count <= 0;
      mig_state <= IDLE_W;
      wr_counter <= 0;
    end else begin
      // Assign valid_in between equal to zero if this is the case
      case (mig_state)
        IDLE_W: begin
          app_en <= 0;
          if (wr_counter == 80 * 32) begin
            state <= IDLE_R;
            wr_counter <= 72 * 32; // Removed the sync marker bits
            app_addr <= (offset + 36 * 2048) % BIG_DEL;
          end else begin
            app_cmd <= 0;
            app_wdf_data <= 0;
            app_wdf_end <= 0;
            app_wdf_wren <= 0;
            app_wdf_mask <= 0;
            if (inp_m_valid) begin
              state <= CALC_DEL;
              inp_m_ready <= 0;
              mig_hold_val <= inp_data_m;
            end else begin
              inp_m_ready <= 1;
            end
          end
        end
        CALC_DEL: begin
          delay <=  ((cur_branch == 36) ? 0 : cur_branch) * 2048 * 36;
          // Check if sync marker and increment count
          
          if (app_wdf_rdy) begin
            if (cur_branch == 0 && sync_mark_count != 7) begin
                wr_counter <= wr_counter + 1;
                sync_mark_count <= sync_mark_count + 1;
                state <= IDLE_W;
            end else begin
              sync_mark_count <= 0;
              app_cmd <= 0;
              app_en <= 0;
              app_wdf_data <= mig_hold_val;
              app_wdf_end <= 1;
              app_wdf_wren <= 1;
              app_wdf_mask <= 0;
              state <= CALC_ADDR;
            end
          end
        end
        CALC_ADDR: begin
          if (app_rdy) begin
            // Write to addr
            app_addr = (offset - delay + BIG_DEL) % BIG_DEL;
            app_cmd = 0;
            app_en = 1;
            app_wdf_data = 0;
            app_wdf_end = 0;
            app_wdf_wren = 0;
            app_wdf_mask = 0;
            state <= IDLE_W;
            offset <= (offset == BIG_DEL - 1) ? 0 : offset + 1;
            cur_branch <= (cur_branch == 72 - 1) ? 0 : cur_branch + 1;
            wr_counter <= wr_counter + 1;
          end
        end
        IDLE_R: begin
          // Make 80 * 32 reads
          // Should at least reduce overflow at the recivening fifo
          //
          if (app_rdy && out_s_ready) begin
            app_addr <= wr_counter;
            app_cmd <= 1;
            app_en <= 1;
            app_wdf_data <= 0;
            app_wdf_end <= 0;
            app_wdf_wren <= 0;
            app_wdf_mask <= 0;
            wr_counter <= wr_counter - 1;
          end else begin 
            app_en <= 0;
          end
          if (wr_counter == 0) begin
            state <= IDLE_R;
          end
        end
      endcase
    end
  end

  assign app_rd_data = out_data_s; 
  assign app_rd_data_valid = out_s_valid;
  

endmodule

`default_nettype wire

