`timescale 1ns / 1ps
`default_nettype none

module viterbi_tb;

  logic clk;
  logic sys_rst;
  logic signed [7:0] soft_inp;
  logic valid_in_vit;
  logic ready_in;
  logic vit_desc;
  logic valid_out;
  logic normalization;
  logic [19:0] sm_0_debug;

  // TBU DEBUG STUFF:
  logic [5:0] prev_state_TBU_deb [63:0];
  logic desc_TBU_deb [63:0];
  logic valid_in_TBU_deb;

  viterbi dut (
      .clk(clk),
      .sys_rst(sys_rst),
      .soft_inp(soft_inp),
      .valid_in_vit(valid_in_vit),
      .vit_desc(vit_desc),
      .normalization(normalization),
      .ready_in(ready_in),
      .sm_0_debug(sm_0_debug),
      // TBU DEBUG
      .prev_state_TBU_deb(prev_state_TBU_deb),
      .desc_TBU_deb(desc_TBU_deb),
      .valid_in_TBU_deb(valid_in_TBU_deb),
      .valid_out_vit(valid_out)
  );

  always begin
    #5 clk = ~clk;
  end

  // function automatic void states(
  //     output reg [STATE_WIDTH-1:0] states[0:NUM_ITERATIONS-1],
  //     output reg inputs[0:NUM_ITERATIONS-1],
  //     output reg out_seen[0:2*NUM_ITERATIONS-1],
  //     output reg [STATE_WIDTH-1:0] state,
  //     output reg inp_bit
  // );

  // task check_acs;
  // integer trellis_stage;
  // begin
  //   trellis_stage = 0;
  //   while (1) begin
  //     @ (posedge clk);  // Wait for the clock edge
  //     if (valid_in_TBU_deb == 1'b1) begin  // Check if the signal is high
  //       if (prev_state_TBU_deb[] == expected_state) begin  // Check if the previous state matches the expected state
  //         $display("Signal is high and previous state matches the expected state");
  //       end else begin
  //         $display("Signal is high but previous state does not match the expected state");
  //       end
  //     end
  //   end
  // end
  // endtask


  function automatic bit [1:0] conv_calc(bit [5:0] state, bit in_bit);
    bit [6:0] g1 = ((in_bit << 6) | state) & 7'h79;
    bit [6:0] g2 = ((in_bit << 6) | state) & 7'h5B;
    conv_calc[0] = ($countones(g1) % 2); 
    conv_calc[1] = ($countones(g2) % 2);
  endfunction

  bit [5:0] state;
  bit inp_bit;
  bit [1:0] out_seen; // {q, i}
  //

  logic input_bits [139:0];
  int inp_seed = 10;



  initial begin
    $dumpfile("vcd/vit.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,viterbi_tb); //dump all variables in this module
    $display("Starting Sim"); //print nice message at start
    clk = 0;
    state = 0;
    inp_bit = 0;

    sys_rst = 1;
    valid_in_vit = 0;
    #10 
    sys_rst = 0;
    valid_in_vit = 1;

    
    for (int i = 0; i < 140; i++) begin
      /* inp_bit = $random(inp_seed); */
      $display("count: %d", i);
      $display("Input bit: %d", inp_bit);
      out_seen = conv_calc(state, inp_bit);
      soft_inp = (out_seen[0]) ? 8'h7F : 8'h80;
      #10;
      soft_inp = (out_seen[1]) ? 8'h7F : 8'h80;
      state = (state >> 1) | (inp_bit << 5);
      $display("State: %d", state);
      inp_bit = ~inp_bit;
      #10;
    end
    #1000;
    $display("Simulation finished");
    $finish;
  end

endmodule
`default_nettype wire
