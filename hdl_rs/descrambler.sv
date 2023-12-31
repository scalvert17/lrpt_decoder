`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
descrambler and lfsr_8 modules take in a symbol at a time and xor it with a byte of noise produced by lfsr_8.
*/

module descrambler(
  input wire clk_in,
  input wire rst_in,
  input wire cvcdu_new,         //Indicates beginning of a CVCDU
  input wire data_valid_in,     //SINGLE CYCLE HIGH FOR TESTING; indicate new byte; idk how it will really behave
  input wire [7:0] byte_in,     //Incoming scrambled byte
  output logic [7:0] byte_out,  //Descrambled byte
  output logic data_valid_out   //Indicate byte_out is valid
  );

  localparam CALC_NOISE = 0;
  localparam IDLE = 1;
  
  logic state;
  logic [3:0] counter;
  logic need_new_bit;
  logic [7:0] noise_out;
  logic [7:0] noise_byte;

  always_ff @(posedge clk_in) begin
    if (rst_in || cvcdu_new) begin
      state <= IDLE;
      counter <= 0;
      byte_out <= 0;
      

    
    end else begin
      case(state)
        
        CALC_NOISE: begin
          noise_byte <= noise_out;
          counter <= counter + 1;
          if (counter == 7) begin
            need_new_bit <= 0;
            byte_out <= byte_in ^ noise_byte;
            data_valid_out <= 1;
            state <= IDLE;
          end
        end
        
        IDLE: begin
          data_valid_out <= 0;
          byte_out <= byte_in
          if (data_valid_in) begin
            need_new_bit <= 1;
            //data_valid_out <= 0;
            state <= CALC_NOISE;
          end
        end
      endcase
    end
  end


  lfsr_8 lfsr_8_gen(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .cvcdu_new(cvcdu_new),
    .data_valid_in(need_new_bit),
    .noise_out(noise_out)
  );

endmodule  //descrambler




module lfsr_8 #(parameter SEED = 8'b1111_1111) (
  input wire clk_in,
  input wire rst_in,
  input wire cvcdu_new,          //Indicates beginning of a CVCDU
  input wire data_valid_in,      //Indicates a new byte of the bitstream; need new noise byte
  output logic [7:0] noise_out  //Byte of pseudo-noise
  );

  logic [7:0] state;

  always_ff @(posedge clk_in) begin
    if (rst_in || cvcdu_new) begin
      noise_out <= SEED;

    end else if (data_valid_in) begin
      noise_out <= (noise_out >> 1) | (((noise_out>>7 & 8'b0000_0001) ^ 
                                        (noise_out>>5 & 8'b0000_0001) ^ 
                                        (noise_out>>3 & 8'b0000_0001) ^ 
                                        (noise_out & 8'b0000_0001)) << 7);
    
    end
  end
endmodule


  /*
  TESTBENCHING
  The whole sequence should be:
    0xff, 0x48, 0x0e, 0xc0, 0x9a, 0x0d, 0x70, 0xbc,
    0x8e, 0x2c, 0x93, 0xad, 0xa7, 0xb7, 0x46, 0xce,
    0x5a, 0x97, 0x7d, 0xcc, 0x32, 0xa2, 0xbf, 0x3e,
    0x0a, 0x10, 0xf1, 0x88, 0x94, 0xcd, 0xea, 0xb1,
    0xfe, 0x90, 0x1d, 0x81, 0x34, 0x1a, 0xe1, 0x79,
    0x1c, 0x59, 0x27, 0x5b, 0x4f, 0x6e, 0x8d, 0x9c,
    0xb5, 0x2e, 0xfb, 0x98, 0x65, 0x45, 0x7e, 0x7c,
    0x14, 0x21, 0xe3, 0x11, 0x29, 0x9b, 0xd5, 0x63,
    0xfd, 0x20, 0x3b, 0x02, 0x68, 0x35, 0xc2, 0xf2,
    0x38, 0xb2, 0x4e, 0xb6, 0x9e, 0xdd, 0x1b, 0x39,
    0x6a, 0x5d, 0xf7, 0x30, 0xca, 0x8a, 0xfc, 0xf8,
    0x28, 0x43, 0xc6, 0x22, 0x53, 0x37, 0xaa, 0xc7,
    0xfa, 0x40, 0x76, 0x04, 0xd0, 0x6b, 0x85, 0xe4,
    0x71, 0x64, 0x9d, 0x6d, 0x3d, 0xba, 0x36, 0x72,
    0xd4, 0xbb, 0xee, 0x61, 0x95, 0x15, 0xf9, 0xf0,
    0x50, 0x87, 0x8c, 0x44, 0xa6, 0x6f, 0x55, 0x8f,
    0xf4, 0x80, 0xec, 0x09, 0xa0, 0xd7, 0x0b, 0xc8,
    0xe2, 0xc9, 0x3a, 0xda, 0x7b, 0x74, 0x6c, 0xe5,
    0xa9, 0x77, 0xdc, 0xc3, 0x2a, 0x2b, 0xf3, 0xe0,
    0xa1, 0x0f, 0x18, 0x89, 0x4c, 0xde, 0xab, 0x1f,
    0xe9, 0x01, 0xd8, 0x13, 0x41, 0xae, 0x17, 0x91,
    0xc5, 0x92, 0x75, 0xb4, 0xf6, 0xe8, 0xd9, 0xcb,
    0x52, 0xef, 0xb9, 0x86, 0x54, 0x57, 0xe7, 0xc1,
    0x42, 0x1e, 0x31, 0x12, 0x99, 0xbd, 0x56, 0x3f,
    0xd2, 0x03, 0xb0, 0x26, 0x83, 0x5c, 0x2f, 0x23,
    0x8b, 0x24, 0xeb, 0x69, 0xed, 0xd1, 0xb3, 0x96,
    0xa5, 0xdf, 0x73, 0x0c, 0xa8, 0xaf, 0xcf, 0x82,
    0x84, 0x3c, 0x62, 0x25, 0x33, 0x7a, 0xac, 0x7f,
    0xa4, 0x07, 0x60, 0x4d, 0x06, 0xb8, 0x5e, 0x47,
    0x16, 0x49, 0xd6, 0xd3, 0xdb, 0xa3, 0x67, 0x2d,
    0x4b, 0xbe, 0xe6, 0x19, 0x51, 0x5f, 0x9f, 0x05,
    0x08, 0x78, 0xc4, 0x4a, 0x66, 0xf5, 0x58


    Idk whether it'd be better to just look it up or generate a new byte each time.
    Also, the CCSDS specification says the lfsr is reset after 255 bits. Other places say 255 bytes. I think it's bytes.

    If that's true, then each incoming byte is xor'd with it's corresponding byte. Probably have a signal indicating the start of a CVCDU which
    will reset the lfsr. Then check if its equal to 255 or modulo it. Idk which would be more efficient, can find out later.
  */

`default_nettype wire
