`timescale 1ns / 1ps
`default_nettype none

/*
* Expects as input I/Q data in offset binary. That is 0xFF is the strongest 1 representation and 
* 0x00 is the strongest 0 representation 
*/
module viterbi (
  input wire clk,
  input wire sys_rst,
  input wire signed [7:0] soft_inp,
  input wire valid_in_vit,

  output logic vit_desc,
  output logic ready_in,
  output logic normalization,
  output logic [19:0] sm_0_debug,
  output logic  valid_out_vit
  
);
  assign sm_0_debug = sm[0];
  localparam K = 7; // Constraint length
  localparam INV_R = 2; // 2x bits on output as input on encoder (r = 1/2)
  localparam NUM_STATES = 2**(K - 1); // states of encoding shift register
  //
  localparam STATE_MET_WIDTH = 20; // Width of state metric
  
  logic signed [7:0] input_i;
  logic signed [7:0] input_q;


  //TODO: Check that pm doesn't overflow
  logic [STATE_MET_WIDTH-1:0] sm [NUM_STATES-1:0];
  logic [STATE_MET_WIDTH-1:0] sm_normal [NUM_STATES-1:0];

  logic [STATE_MET_WIDTH-1:0] met_out [3:0]; 

  
  // For the ACS
  logic desc [NUM_STATES-1:0];
  logic valid_out [NUM_STATES-1:0];
  logic [K-2:0] prev_state [NUM_STATES-1:0];
  
  logic flag;
  logic signed [STATE_MET_WIDTH:0] sub_res [NUM_STATES-1:0];
  logic i_q_counter;
  logic valid_in; // For acs
  // Was for fligging msb of inp
  // logic first_inp;

  // initial first_inp = 1;

  assign input_q = {~soft_inp[7], soft_inp[6:0]};

  always_ff @(posedge clk) begin
    if (sys_rst) begin
      input_i <= 0;
      ready_in <= 0;
      valid_in <= 0;
      i_q_counter <= 0;
      // first_inp <= 1;
    end else begin
      if (valid_in_vit) begin
        if (!i_q_counter) begin
          i_q_counter <= 1; 
          // TODO:Check that flipping the MSB is what we want to do 
          // Might be the other direction. I seemed to think that -1 = 0 and 1 = 1
          input_i <= {~soft_inp[7], soft_inp[6:0]};
          valid_in <= 0;
        end else begin
          i_q_counter <= 0;
          valid_in <= 1;
        end
      end
    end
  end

  // Debugging
  // logic temp;
  // always_ff @(posedge clk) begin
  //   if (sys_rst) begin
  //     sm_out_deb <= 0;
  //   end else if (valid_in_vit) begin
  //     temp = 0;
  //     for (int i = 0; i < NUM_STATES; i = i + 1) begin
  //       temp = sm[i] ^ temp;
  //     end
  //     sm_out_deb <= temp;
  //   end
  // end


  // TODO: Generate these modules
  bmu #(
    .EXP_OBS_OUT(2'b00)
  ) bmu_00 (
    .clk(clk),
    .sys_rst(sys_rst),
    .input_i(input_i),
    .input_q(input_q),
    .met_out(met_out[0])
  );

  bmu #(
    .EXP_OBS_OUT(2'b01)
  ) bmu_01 (
    .clk(clk),
    .sys_rst(sys_rst),
    .input_i(input_i),
    .input_q(input_q),
    .met_out(met_out[1])
  );

  bmu #(
    .EXP_OBS_OUT(2'b10)
  ) bmu_10 (
    .clk(clk),
    .sys_rst(sys_rst),
    .input_i(input_i),
    .input_q(input_q),
    .met_out(met_out[2])
  );

  bmu #(
    .EXP_OBS_OUT(2'b11)
  ) bmu_11 (
    .clk(clk),
    .sys_rst(sys_rst),
    .input_i(input_i),
    .input_q(input_q),
    .met_out(met_out[3])
  );



  always_comb begin 
    for (int i = 0; i < NUM_STATES; i = i + 1) begin
      // Subtraction of 2**19 ~ (2**20 - 1) / 2 so midpoint of our state metrics 
      sub_res[i] = $signed({1'b0, sm[i]}) + ~(20'h80000) + 1'b1; 
    end
    flag = 1;
    for (int i = 0; i < NUM_STATES; i = i + 1) begin
      if (sub_res[i] < 0) begin
        flag = 0;
      end
    end
  end

  // initial begin
  //   prev_state[i] <= 0;
  //   desc[i] <= 0;
  //   sm[i] <= 0;
  // end

  // TODO: Add a valid input signal to the normalizer
  // TODO: Add a signal to tell when normalizing 
  genvar i;
  generate
    for (i = 0; i < NUM_STATES; i = i + 1) begin
      always_ff @(posedge clk) begin
        if (sys_rst) begin
          sm_normal[i] <= 0;
          // prev_state[i] <= 0;
          // desc[i] <= 0;
          // sm[i] <= 0;
        end else begin
          if (flag) begin
            sm_normal[i] <= sub_res[i];
          end else begin
            sm_normal[i] <= sm[i];
          end
        end
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (sys_rst) begin
      normalization <= 0;
    end else if (flag) begin
      normalization <= 1;
    end else begin
      normalization <= 0;
    end
  end


//TODO: Does this work?
// genvar i;
// generate
//   for (i = 0; i < 32; i=i+2) begin : acs_gen
//     acs_butterfly #(
//       .TRANSITION_BIT(0),
//       .STATE_0(6'di),
//       .STATE_1(6'd(i+1))
//     ) acs_inst (
//       .clk(clk),
//       .sys_rst(sys_rst),
//       .bm_0(met_out[i/2]),
//       .bm_1(met_out[(i/2)+1]),
//       .sm_0(sm_normal[i]),
//       .sm_1(sm_normal[i+1]),
//       .valid_in(valid_in),
//       .desc(desc[i/2]),
//       .valid_out(valid_out[i/2]),
//       .sm_out(sm[i/2]),
//       .prev_state(prev_state[i/2])
//     );
//   end
// endgenerate

  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd0),
    .STATE_1(6'd1)
  ) acs_0 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[0]),
    .sm_1(sm_normal[1]),
    .valid_in(valid_in),
    .desc(desc[0]),
    .valid_out(valid_out[0]),
    .sm_out(sm[0]),
    .prev_state(prev_state[0])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd2),
    .STATE_1(6'd3)
  ) acs_1 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[2]),
    .sm_1(sm_normal[3]),
    .valid_in(valid_in),
    .desc(desc[1]),
    .valid_out(valid_out[1]),
    .sm_out(sm[1]),
    .prev_state(prev_state[1])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd4),
    .STATE_1(6'd5)
  ) acs_2 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[4]),
    .sm_1(sm_normal[5]),
    .valid_in(valid_in),
    .desc(desc[2]),
    .valid_out(valid_out[2]),
    .sm_out(sm[2]),
    .prev_state(prev_state[2])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd6),
    .STATE_1(6'd7)
  ) acs_3 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[6]),
    .sm_1(sm_normal[7]),
    .valid_in(valid_in),
    .desc(desc[3]),
    .valid_out(valid_out[3]),
    .sm_out(sm[3]),
    .prev_state(prev_state[3])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd8),
    .STATE_1(6'd9)
  ) acs_4 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[8]),
    .sm_1(sm_normal[9]),
    .valid_in(valid_in),
    .desc(desc[4]),
    .valid_out(valid_out[4]),
    .sm_out(sm[4]),
    .prev_state(prev_state[4])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd10),
    .STATE_1(6'd11)
  ) acs_5 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[10]),
    .sm_1(sm_normal[11]),
    .valid_in(valid_in),
    .desc(desc[5]),
    .valid_out(valid_out[5]),
    .sm_out(sm[5]),
    .prev_state(prev_state[5])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd12),
    .STATE_1(6'd13)
  ) acs_6 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[12]),
    .sm_1(sm_normal[13]),
    .valid_in(valid_in),
    .desc(desc[6]),
    .valid_out(valid_out[6]),
    .sm_out(sm[6]),
    .prev_state(prev_state[6])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd14),
    .STATE_1(6'd15)
  ) acs_7 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[14]),
    .sm_1(sm_normal[15]),
    .valid_in(valid_in),
    .desc(desc[7]),
    .valid_out(valid_out[7]),
    .sm_out(sm[7]),
    .prev_state(prev_state[7])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd16),
    .STATE_1(6'd17)
  ) acs_8 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[16]),
    .sm_1(sm_normal[17]),
    .valid_in(valid_in),
    .desc(desc[8]),
    .valid_out(valid_out[8]),
    .sm_out(sm[8]),
    .prev_state(prev_state[8])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd18),
    .STATE_1(6'd19)
  ) acs_9 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[18]),
    .sm_1(sm_normal[19]),
    .valid_in(valid_in),
    .desc(desc[9]),
    .valid_out(valid_out[9]),
    .sm_out(sm[9]),
    .prev_state(prev_state[9])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd20),
    .STATE_1(6'd21)
  ) acs_10 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[20]),
    .sm_1(sm_normal[21]),
    .valid_in(valid_in),
    .desc(desc[10]),
    .valid_out(valid_out[10]),
    .sm_out(sm[10]),
    .prev_state(prev_state[10])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd22),
    .STATE_1(6'd23)
  ) acs_11 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[22]),
    .sm_1(sm_normal[23]),
    .valid_in(valid_in),
    .desc(desc[11]),
    .valid_out(valid_out[11]),
    .sm_out(sm[11]),
    .prev_state(prev_state[11])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd24),
    .STATE_1(6'd25)
  ) acs_12 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[24]),
    .sm_1(sm_normal[25]),
    .valid_in(valid_in),
    .desc(desc[12]),
    .valid_out(valid_out[12]),
    .sm_out(sm[12]),
    .prev_state(prev_state[12])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd26),
    .STATE_1(6'd27)
  ) acs_13 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[26]),
    .sm_1(sm_normal[27]),
    .valid_in(valid_in),
    .desc(desc[13]),
    .valid_out(valid_out[13]),
    .sm_out(sm[13]),
    .prev_state(prev_state[13])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd28),
    .STATE_1(6'd29)
  ) acs_14 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[28]),
    .sm_1(sm_normal[29]),
    .valid_in(valid_in),
    .desc(desc[14]),
    .valid_out(valid_out[14]),
    .sm_out(sm[14]),
    .prev_state(prev_state[14])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd30),
    .STATE_1(6'd31)
  ) acs_15 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[30]),
    .sm_1(sm_normal[31]),
    .valid_in(valid_in),
    .desc(desc[15]),
    .valid_out(valid_out[15]),
    .sm_out(sm[15]),
    .prev_state(prev_state[15])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd32),
    .STATE_1(6'd33)
  ) acs_16 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[32]),
    .sm_1(sm_normal[33]),
    .valid_in(valid_in),
    .desc(desc[16]),
    .valid_out(valid_out[16]),
    .sm_out(sm[16]),
    .prev_state(prev_state[16])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd34),
    .STATE_1(6'd35)
  ) acs_17 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[34]),
    .sm_1(sm_normal[35]),
    .valid_in(valid_in),
    .desc(desc[17]),
    .valid_out(valid_out[17]),
    .sm_out(sm[17]),
    .prev_state(prev_state[17])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd36),
    .STATE_1(6'd37)
  ) acs_18 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[36]),
    .sm_1(sm_normal[37]),
    .valid_in(valid_in),
    .desc(desc[18]),
    .valid_out(valid_out[18]),
    .sm_out(sm[18]),
    .prev_state(prev_state[18])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd38),
    .STATE_1(6'd39)
  ) acs_19 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[38]),
    .sm_1(sm_normal[39]),
    .valid_in(valid_in),
    .desc(desc[19]),
    .valid_out(valid_out[19]),
    .sm_out(sm[19]),
    .prev_state(prev_state[19])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd40),
    .STATE_1(6'd41)
  ) acs_20 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[40]),
    .sm_1(sm_normal[41]),
    .valid_in(valid_in),
    .desc(desc[20]),
    .valid_out(valid_out[20]),
    .sm_out(sm[20]),
    .prev_state(prev_state[20])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd42),
    .STATE_1(6'd43)
  ) acs_21 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[42]),
    .sm_1(sm_normal[43]),
    .valid_in(valid_in),
    .desc(desc[21]),
    .valid_out(valid_out[21]),
    .sm_out(sm[21]),
    .prev_state(prev_state[21])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd44),
    .STATE_1(6'd45)
  ) acs_22 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[44]),
    .sm_1(sm_normal[45]),
    .valid_in(valid_in),
    .desc(desc[22]),
    .valid_out(valid_out[22]),
    .sm_out(sm[22]),
    .prev_state(prev_state[22])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd46),
    .STATE_1(6'd47)
  ) acs_23 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[46]),
    .sm_1(sm_normal[47]),
    .valid_in(valid_in),
    .desc(desc[23]),
    .valid_out(valid_out[23]),
    .sm_out(sm[23]),
    .prev_state(prev_state[23])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd48),
    .STATE_1(6'd49)
  ) acs_24 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[48]),
    .sm_1(sm_normal[49]),
    .valid_in(valid_in),
    .desc(desc[24]),
    .valid_out(valid_out[24]),
    .sm_out(sm[24]),
    .prev_state(prev_state[24])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd50),
    .STATE_1(6'd51)
  ) acs_25 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[50]),
    .sm_1(sm_normal[51]),
    .valid_in(valid_in),
    .desc(desc[25]),
    .valid_out(valid_out[25]),
    .sm_out(sm[25]),
    .prev_state(prev_state[25])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd52),
    .STATE_1(6'd53)
  ) acs_26 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[52]),
    .sm_1(sm_normal[53]),
    .valid_in(valid_in),
    .desc(desc[26]),
    .valid_out(valid_out[26]),
    .sm_out(sm[26]),
    .prev_state(prev_state[26])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd54),
    .STATE_1(6'd55)
  ) acs_27 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[54]),
    .sm_1(sm_normal[55]),
    .valid_in(valid_in),
    .desc(desc[27]),
    .valid_out(valid_out[27]),
    .sm_out(sm[27]),
    .prev_state(prev_state[27])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd56),
    .STATE_1(6'd57)
  ) acs_28 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[56]),
    .sm_1(sm_normal[57]),
    .valid_in(valid_in),
    .desc(desc[28]),
    .valid_out(valid_out[28]),
    .sm_out(sm[28]),
    .prev_state(prev_state[28])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd58),
    .STATE_1(6'd59)
  ) acs_29 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[58]),
    .sm_1(sm_normal[59]),
    .valid_in(valid_in),
    .desc(desc[29]),
    .valid_out(valid_out[29]),
    .sm_out(sm[29]),
    .prev_state(prev_state[29])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd60),
    .STATE_1(6'd61)
  ) acs_30 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[60]),
    .sm_1(sm_normal[61]),
    .valid_in(valid_in),
    .desc(desc[30]),
    .valid_out(valid_out[30]),
    .sm_out(sm[30]),
    .prev_state(prev_state[30])
  );
  acs_butterfly #(
    .TRANSITION_BIT(0),
    .STATE_0(6'd62),
    .STATE_1(6'd63)
  ) acs_31 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[62]),
    .sm_1(sm_normal[63]),
    .valid_in(valid_in),
    .desc(desc[31]),
    .valid_out(valid_out[31]),
    .sm_out(sm[31]),
    .prev_state(prev_state[31])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd0),
    .STATE_1(6'd1)
  ) acs_32 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[0]),
    .sm_1(sm_normal[1]),
    .valid_in(valid_in),
    .desc(desc[32]),
    .valid_out(valid_out[32]),
    .sm_out(sm[32]),
    .prev_state(prev_state[32])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd2),
    .STATE_1(6'd3)
  ) acs_33 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[2]),
    .sm_1(sm_normal[3]),
    .valid_in(valid_in),
    .desc(desc[33]),
    .valid_out(valid_out[33]),
    .sm_out(sm[33]),
    .prev_state(prev_state[33])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd4),
    .STATE_1(6'd5)
  ) acs_34 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[4]),
    .sm_1(sm_normal[5]),
    .valid_in(valid_in),
    .desc(desc[34]),
    .valid_out(valid_out[34]),
    .sm_out(sm[34]),
    .prev_state(prev_state[34])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd6),
    .STATE_1(6'd7)
  ) acs_35 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[6]),
    .sm_1(sm_normal[7]),
    .valid_in(valid_in),
    .desc(desc[35]),
    .valid_out(valid_out[35]),
    .sm_out(sm[35]),
    .prev_state(prev_state[35])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd8),
    .STATE_1(6'd9)
  ) acs_36 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[8]),
    .sm_1(sm_normal[9]),
    .valid_in(valid_in),
    .desc(desc[36]),
    .valid_out(valid_out[36]),
    .sm_out(sm[36]),
    .prev_state(prev_state[36])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd10),
    .STATE_1(6'd11)
  ) acs_37 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[10]),
    .sm_1(sm_normal[11]),
    .valid_in(valid_in),
    .desc(desc[37]),
    .valid_out(valid_out[37]),
    .sm_out(sm[37]),
    .prev_state(prev_state[37])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd12),
    .STATE_1(6'd13)
  ) acs_38 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[12]),
    .sm_1(sm_normal[13]),
    .valid_in(valid_in),
    .desc(desc[38]),
    .valid_out(valid_out[38]),
    .sm_out(sm[38]),
    .prev_state(prev_state[38])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd14),
    .STATE_1(6'd15)
  ) acs_39 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[14]),
    .sm_1(sm_normal[15]),
    .valid_in(valid_in),
    .desc(desc[39]),
    .valid_out(valid_out[39]),
    .sm_out(sm[39]),
    .prev_state(prev_state[39])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd16),
    .STATE_1(6'd17)
  ) acs_40 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[16]),
    .sm_1(sm_normal[17]),
    .valid_in(valid_in),
    .desc(desc[40]),
    .valid_out(valid_out[40]),
    .sm_out(sm[40]),
    .prev_state(prev_state[40])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd18),
    .STATE_1(6'd19)
  ) acs_41 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[18]),
    .sm_1(sm_normal[19]),
    .valid_in(valid_in),
    .desc(desc[41]),
    .valid_out(valid_out[41]),
    .sm_out(sm[41]),
    .prev_state(prev_state[41])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd20),
    .STATE_1(6'd21)
  ) acs_42 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[20]),
    .sm_1(sm_normal[21]),
    .valid_in(valid_in),
    .desc(desc[42]),
    .valid_out(valid_out[42]),
    .sm_out(sm[42]),
    .prev_state(prev_state[42])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd22),
    .STATE_1(6'd23)
  ) acs_43 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[22]),
    .sm_1(sm_normal[23]),
    .valid_in(valid_in),
    .desc(desc[43]),
    .valid_out(valid_out[43]),
    .sm_out(sm[43]),
    .prev_state(prev_state[43])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd24),
    .STATE_1(6'd25)
  ) acs_44 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[24]),
    .sm_1(sm_normal[25]),
    .valid_in(valid_in),
    .desc(desc[44]),
    .valid_out(valid_out[44]),
    .sm_out(sm[44]),
    .prev_state(prev_state[44])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd26),
    .STATE_1(6'd27)
  ) acs_45 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[26]),
    .sm_1(sm_normal[27]),
    .valid_in(valid_in),
    .desc(desc[45]),
    .valid_out(valid_out[45]),
    .sm_out(sm[45]),
    .prev_state(prev_state[45])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd28),
    .STATE_1(6'd29)
  ) acs_46 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[28]),
    .sm_1(sm_normal[29]),
    .valid_in(valid_in),
    .desc(desc[46]),
    .valid_out(valid_out[46]),
    .sm_out(sm[46]),
    .prev_state(prev_state[46])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd30),
    .STATE_1(6'd31)
  ) acs_47 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[30]),
    .sm_1(sm_normal[31]),
    .valid_in(valid_in),
    .desc(desc[47]),
    .valid_out(valid_out[47]),
    .sm_out(sm[47]),
    .prev_state(prev_state[47])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd32),
    .STATE_1(6'd33)
  ) acs_48 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[32]),
    .sm_1(sm_normal[33]),
    .valid_in(valid_in),
    .desc(desc[48]),
    .valid_out(valid_out[48]),
    .sm_out(sm[48]),
    .prev_state(prev_state[48])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd34),
    .STATE_1(6'd35)
  ) acs_49 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[34]),
    .sm_1(sm_normal[35]),
    .valid_in(valid_in),
    .desc(desc[49]),
    .valid_out(valid_out[49]),
    .sm_out(sm[49]),
    .prev_state(prev_state[49])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd36),
    .STATE_1(6'd37)
  ) acs_50 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[36]),
    .sm_1(sm_normal[37]),
    .valid_in(valid_in),
    .desc(desc[50]),
    .valid_out(valid_out[50]),
    .sm_out(sm[50]),
    .prev_state(prev_state[50])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd38),
    .STATE_1(6'd39)
  ) acs_51 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[38]),
    .sm_1(sm_normal[39]),
    .valid_in(valid_in),
    .desc(desc[51]),
    .valid_out(valid_out[51]),
    .sm_out(sm[51]),
    .prev_state(prev_state[51])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd40),
    .STATE_1(6'd41)
  ) acs_52 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[40]),
    .sm_1(sm_normal[41]),
    .valid_in(valid_in),
    .desc(desc[52]),
    .valid_out(valid_out[52]),
    .sm_out(sm[52]),
    .prev_state(prev_state[52])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd42),
    .STATE_1(6'd43)
  ) acs_53 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[42]),
    .sm_1(sm_normal[43]),
    .valid_in(valid_in),
    .desc(desc[53]),
    .valid_out(valid_out[53]),
    .sm_out(sm[53]),
    .prev_state(prev_state[53])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd44),
    .STATE_1(6'd45)
  ) acs_54 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[44]),
    .sm_1(sm_normal[45]),
    .valid_in(valid_in),
    .desc(desc[54]),
    .valid_out(valid_out[54]),
    .sm_out(sm[54]),
    .prev_state(prev_state[54])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd46),
    .STATE_1(6'd47)
  ) acs_55 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[46]),
    .sm_1(sm_normal[47]),
    .valid_in(valid_in),
    .desc(desc[55]),
    .valid_out(valid_out[55]),
    .sm_out(sm[55]),
    .prev_state(prev_state[55])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd48),
    .STATE_1(6'd49)
  ) acs_56 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[48]),
    .sm_1(sm_normal[49]),
    .valid_in(valid_in),
    .desc(desc[56]),
    .valid_out(valid_out[56]),
    .sm_out(sm[56]),
    .prev_state(prev_state[56])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd50),
    .STATE_1(6'd51)
  ) acs_57 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[50]),
    .sm_1(sm_normal[51]),
    .valid_in(valid_in),
    .desc(desc[57]),
    .valid_out(valid_out[57]),
    .sm_out(sm[57]),
    .prev_state(prev_state[57])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd52),
    .STATE_1(6'd53)
  ) acs_58 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[2]),
    .bm_1(met_out[1]),
    .sm_0(sm_normal[52]),
    .sm_1(sm_normal[53]),
    .valid_in(valid_in),
    .desc(desc[58]),
    .valid_out(valid_out[58]),
    .sm_out(sm[58]),
    .prev_state(prev_state[58])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd54),
    .STATE_1(6'd55)
  ) acs_59 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[3]),
    .bm_1(met_out[0]),
    .sm_0(sm_normal[54]),
    .sm_1(sm_normal[55]),
    .valid_in(valid_in),
    .desc(desc[59]),
    .valid_out(valid_out[59]),
    .sm_out(sm[59]),
    .prev_state(prev_state[59])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd56),
    .STATE_1(6'd57)
  ) acs_60 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[56]),
    .sm_1(sm_normal[57]),
    .valid_in(valid_in),
    .desc(desc[60]),
    .valid_out(valid_out[60]),
    .sm_out(sm[60]),
    .prev_state(prev_state[60])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd58),
    .STATE_1(6'd59)
  ) acs_61 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[58]),
    .sm_1(sm_normal[59]),
    .valid_in(valid_in),
    .desc(desc[61]),
    .valid_out(valid_out[61]),
    .sm_out(sm[61]),
    .prev_state(prev_state[61])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd60),
    .STATE_1(6'd61)
  ) acs_62 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[1]),
    .bm_1(met_out[2]),
    .sm_0(sm_normal[60]),
    .sm_1(sm_normal[61]),
    .valid_in(valid_in),
    .desc(desc[62]),
    .valid_out(valid_out[62]),
    .sm_out(sm[62]),
    .prev_state(prev_state[62])
  );
  acs_butterfly #(
    .TRANSITION_BIT(1),
    .STATE_0(6'd62),
    .STATE_1(6'd63)
  ) acs_63 (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[0]),
    .bm_1(met_out[3]),
    .sm_0(sm_normal[62]),
    .sm_1(sm_normal[63]),
    .valid_in(valid_in),
    .desc(desc[63]),
    .valid_out(valid_out[63]),
    .sm_out(sm[63]),
    .prev_state(prev_state[63])
  );
  
endmodule


`default_nettype wire
