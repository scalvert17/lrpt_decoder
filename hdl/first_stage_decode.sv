`timescale 1ns / 1ps
`default_nettype none

// TODO: For hard encoding do Gray's so that negative I or Q is 1

/*
* Performs decoding on convolutionally encoded CADUs. Deinterleaves incoming 8bit soft I/Q data 
* and differentially decodes data as specified
*/ 
module first_stage_decode # (
    parameter DIFF_DECODE = 1, // 1 for differential decoding, 0 for no differential decoding
    parameter DEINTERLEAVE = 1 // 1 for deinterleaving, 0 for no deinterleaving
  )(
  input wire clk,
  input wire sys_rst,
  input wire diff_decode,
  input wire deinterleave, 

  input wire signed [7:0] input_soft,

  // TODO: Do we want a stream or buffer of viterbi output 
  output vit_desc,
  output ready_in,  // This is important.TODO: REad in the bits find offset and then shift. Maybe call the uw_sync only once every 6 32 frame 
  output valid_out
  );

  //! Pipeline: 
  // Inp -> UW_sync + derotator -> Conv_deinterleaver -> Diff decode -> Viterbi -> CADU sync


  localparam INTERLEAVE_SYNC_SOFT = 32 * 80; // 32 frames of 80 bytes of soft I/Q 

  logic [$clog2(INTERLEAVE_SYNC_SOFT)-1:0] interleave_offset;
  logic [$clog2(INTERLEAVE_SYNC_SOFT)-1:0] interleave_addr;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(INTERLEAVE_SYNC_SOFT))
    soft_buffer_interleaved (
    .addra(addr_a),
    .clka(clk_in),
    .wea(record_in&&audio_valid_in),
    .dina(audio_in),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(),
    .addrb(addr_b),
    .dinb(),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(dout_b)
  );
// TODO: How to pass the data in brams between. With offset maybe just increment pointer and stuff.
// interleave uw sync and deinterleaver should share one bram to store soft data with the offset 
  // where the uw begins
  // Then after diff_decode need another larger buffer to store CADUs from upstream. Again correlated to 
  // find the start. Hopefully the viterbi 
  // ! UW synch should return rotation, so that we can derotate from there. Should make the other parts easier. 
  // Once uw_synch finds the offset, just shift and read until full buffer. Then start sending the valid bits to
  // uw_again. Maybe add a reset

endmodule

`default_nettype wire


