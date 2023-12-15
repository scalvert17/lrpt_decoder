`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
The syndromes module will take in a symbol at a time and output 32 8-bit syndromes.
*/

module rs_syndromes(
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,     //new cvcdu; will happen every 255 bytes since there are 4 parallel RS instances
  input wire [7:0] r_in,    //data in; coeff of r(x), the polynomial created from the 255 byte code word
  input wire data_valid_in,
  output logic [7:0] s1,    //Syndromes; coeffs of S(x)
  output logic [7:0] s2,
  output logic [7:0] s3,
  output logic [7:0] s4,
  output logic [7:0] s5,
  output logic [7:0] s6,
  output logic [7:0] s7,
  output logic [7:0] s8,
  output logic [7:0] s9,
  output logic [7:0] s10,
  output logic [7:0] s11,
  output logic [7:0] s12,
  output logic [7:0] s13,
  output logic [7:0] s14,
  output logic [7:0] s15,
  output logic [7:0] s16,
  output logic [7:0] s17,
  output logic [7:0] s18,
  output logic [7:0] s19,
  output logic [7:0] s20,
  output logic [7:0] s21,
  output logic [7:0] s22,
  output logic [7:0] s23,
  output logic [7:0] s24,
  output logic [7:0] s25,
  output logic [7:0] s26,
  output logic [7:0] s27,
  output logic [7:0] s28,
  output logic [7:0] s29,
  output logic [7:0] s30,
  output logic [7:0] s31,
  output logic [7:0] s32,
  output logic data_valid_out  //NEED TO SET THIS UP
  );

  logic [7:0] counter;  //know when 255 bytes have been processed

  //Running product after multiplying by alpha^{some power}
  logic [7:0] sum1;
  logic [7:0] sum2;
  logic [7:0] sum3;
  logic [7:0] sum4;
  logic [7:0] sum5;
  logic [7:0] sum6;
  logic [7:0] sum7;
  logic [7:0] sum8;
  logic [7:0] sum9;
  logic [7:0] sum10;
  logic [7:0] sum11;
  logic [7:0] sum12;
  logic [7:0] sum13;
  logic [7:0] sum14;
  logic [7:0] sum15;
  logic [7:0] sum16;
  logic [7:0] sum17;
  logic [7:0] sum18;
  logic [7:0] sum19;
  logic [7:0] sum20;
  logic [7:0] sum21;
  logic [7:0] sum22;
  logic [7:0] sum23;
  logic [7:0] sum24;
  logic [7:0] sum25;
  logic [7:0] sum26;
  logic [7:0] sum27;
  logic [7:0] sum28;
  logic [7:0] sum29;
  logic [7:0] sum30;
  logic [7:0] sum31;
  logic [7:0] sum32;

  
  rs_syn_mult_s1 rs_syn_mult_s1_inst (s1, sum1);
  rs_syn_mult_s2 rs_syn_mult_s2_inst (s2, sum2);
  rs_syn_mult_s3 rs_syn_mult_s3_inst (s3, sum3);
  rs_syn_mult_s4 rs_syn_mult_s4_inst (s4, sum4);
  rs_syn_mult_s5 rs_syn_mult_s5_inst (s5, sum5);
  rs_syn_mult_s6 rs_syn_mult_s6_inst (s6, sum6);
  rs_syn_mult_s7 rs_syn_mult_s7_inst (s7, sum7);
  rs_syn_mult_s8 rs_syn_mult_s8_inst (s8, sum8);
  rs_syn_mult_s9 rs_syn_mult_s9_inst (s9, sum9);
  rs_syn_mult_s10 rs_syn_mult_s10_inst (s10, sum10);
  rs_syn_mult_s11 rs_syn_mult_s11_inst (s11, sum11);
  rs_syn_mult_s12 rs_syn_mult_s12_inst (s12, sum12);
  rs_syn_mult_s13 rs_syn_mult_s13_inst (s13, sum13);
  rs_syn_mult_s14 rs_syn_mult_s14_inst (s14, sum14);
  rs_syn_mult_s15 rs_syn_mult_s15_inst (s15, sum15);
  rs_syn_mult_s16 rs_syn_mult_s16_inst (s16, sum16);
  rs_syn_mult_s17 rs_syn_mult_s17_inst (s17, sum17);
  rs_syn_mult_s18 rs_syn_mult_s18_inst (s18, sum18);
  rs_syn_mult_s19 rs_syn_mult_s19_inst (s19, sum19);
  rs_syn_mult_s20 rs_syn_mult_s20_inst (s20, sum20);
  rs_syn_mult_s21 rs_syn_mult_s21_inst (s21, sum21);
  rs_syn_mult_s22 rs_syn_mult_s22_inst (s22, sum22);
  rs_syn_mult_s23 rs_syn_mult_s23_inst (s23, sum23);
  rs_syn_mult_s24 rs_syn_mult_s24_inst (s24, sum24);
  rs_syn_mult_s25 rs_syn_mult_s25_inst (s25, sum25);
  rs_syn_mult_s26 rs_syn_mult_s26_inst (s26, sum26);
  rs_syn_mult_s27 rs_syn_mult_s27_inst (s27, sum27);
  rs_syn_mult_s28 rs_syn_mult_s28_inst (s28, sum28);
  rs_syn_mult_s29 rs_syn_mult_s29_inst (s29, sum29);
  rs_syn_mult_s30 rs_syn_mult_s30_inst (s30, sum30);
  rs_syn_mult_s31 rs_syn_mult_s31_inst (s31, sum31);
  rs_syn_mult_s32 rs_syn_mult_s32_inst (s32, sum32);
  

  always_ff @(posedge clk_in) begin
    if (rst_in) begin  //set all syndromes to zero
      s1 <= 0;
      s2 <= 0;
      s3 <= 0;
      s4 <= 0;
      s5 <= 0;
      s6 <= 0;
      s7 <= 0;
      s8 <= 0;
      s9 <= 0;
      s10 <= 0;
      s11 <= 0;
      s12 <= 0;
      s13 <= 0;
      s14 <= 0;
      s15 <= 0;
      s16 <= 0;
      s17 <= 0;
      s18 <= 0;
      s19 <= 0;
      s20 <= 0;
      s21 <= 0;
      s22 <= 0;
      s23 <= 0;
      s24 <= 0;
      s25 <= 0;
      s26 <= 0;
      s27 <= 0;
      s28 <= 0;
      s29 <= 0;
      s30 <= 0;
      s31 <= 0;
      s32 <= 0;
      data_valid_out <= 0;

    end else if (new_cvcdu) begin  //load r_254 into syndromes; will get multiplied by alphas
      s1 <= r_in;
      s2 <= r_in; 
      s3 <= r_in; 
      s4 <= r_in; 
      s5 <= r_in; 
      s6 <= r_in; 
      s7 <= r_in; 
      s8 <= r_in; 
      s9 <= r_in; 
      s10 <= r_in;
      s11 <= r_in;
      s12 <= r_in;
      s13 <= r_in;
      s14 <= r_in;
      s15 <= r_in;
      s16 <= r_in;
      s17 <= r_in;
      s18 <= r_in;
      s19 <= r_in;
      s20 <= r_in;
      s21 <= r_in;
      s22 <= r_in;
      s23 <= r_in;
      s24 <= r_in;
      s25 <= r_in;
      s26 <= r_in;
      s27 <= r_in;
      s28 <= r_in;
      s29 <= r_in;
      s30 <= r_in;
      s31 <= r_in;
      s32 <= r_in;
      data_valid_out <= 0;
      counter <= 1;
    
    //end else if (counter == 255) begin
    //  data_valid_out <= 1;
    //  counter <= 0;

    end else if (data_valid_in) begin  //new r value comes in; add it to running sum
      s1 <= sum1 ^ r_in;
      s2 <= sum2 ^ r_in;
      s3 <= sum3 ^ r_in;
      s4 <= sum4 ^ r_in;
      s5 <= sum5 ^ r_in;
      s6 <= sum6 ^ r_in;
      s7 <= sum7 ^ r_in;
      s8 <= sum8 ^ r_in;
      s9 <= sum9 ^ r_in;
      s10 <= sum10 ^ r_in;
      s11 <= sum11 ^ r_in;
      s12 <= sum12 ^ r_in;
      s13 <= sum13 ^ r_in;
      s14 <= sum14 ^ r_in;
      s15 <= sum15 ^ r_in;
      s16 <= sum16 ^ r_in;
      s17 <= sum17 ^ r_in;
      s18 <= sum18 ^ r_in;
      s19 <= sum19 ^ r_in;
      s20 <= sum20 ^ r_in;
      s21 <= sum21 ^ r_in;
      s22 <= sum22 ^ r_in;
      s23 <= sum23 ^ r_in;
      s24 <= sum24 ^ r_in;
      s25 <= sum25 ^ r_in;
      s26 <= sum26 ^ r_in;
      s27 <= sum27 ^ r_in;
      s28 <= sum28 ^ r_in;
      s29 <= sum29 ^ r_in;
      s30 <= sum30 ^ r_in;
      s31 <= sum31 ^ r_in;
      s32 <= sum32 ^ r_in;
      counter <= counter + 1;
      data_valid_out <= 0;
    end
  end
endmodule



////////////////////////////////////////
//Syndrome Multipliers
//  Multiply x by alpha^{some power(p)}.
//  x is a coefficient of r(x).
//  sequence goes as follows with r_254 first
//    S_1 = r_0 + alpha^p(r_1 + alpha^p(r_2 + ... + alpha^p(r_253 + alpha^p * r_254)...))

//Multiply x by alpha^{1}
module rs_syn_mult_s1(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[7];
    y[1] = x[0] ^ x[7];
    y[2] = x[1] ^ x[7];
    y[3] = x[2];
    y[4] = x[3];
    y[5] = x[4];
    y[6] = x[5];
    y[7] = x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{10}
module rs_syn_mult_s2(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6];
    y[1] = x[4] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[3] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[4] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[5] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[6] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{12}
module rs_syn_mult_s3(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[1] ^ x[4] ^ x[6];
    y[1] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[7] = x[0] ^ x[3] ^ x[5];
  end
endmodule


//Multiply x by alpha^{21}
module rs_syn_mult_s4(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
    y[1] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[6];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[7];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[4];
    y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
    y[7] = x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{23}
module rs_syn_mult_s5(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[1] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
    y[2] = x[4] ^ x[7];
    y[3] = x[0] ^ x[5];
    y[4] = x[0] ^ x[1] ^ x[6];
    y[5] = x[0] ^ x[1] ^ x[2] ^ x[7];
    y[6] = x[0] ^ x[1] ^ x[2] ^ x[3];
    y[7] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
  end

endmodule


//Multiply x by alpha^{32}
module rs_syn_mult_s6(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[4] ^ x[6] ^ x[7];
    y[1] = x[1] ^ x[4] ^ x[5] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[4] ^ x[5];
    y[3] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
    y[6] = x[2] ^ x[3] ^ x[4] ^ x[6];
    y[7] = x[3] ^ x[5] ^ x[6];
  end

endmodule


//Multiply x by alpha^{34}
module rs_syn_mult_s7(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[2] ^ x[4] ^ x[5];
    y[1] = x[2] ^ x[3] ^ x[4] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[3] ^ x[7];
    y[3] = x[1] ^ x[3] ^ x[4];
    y[4] = x[0] ^ x[2] ^ x[4] ^ x[5];
    y[5] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6];
    y[6] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
    y[7] = x[1] ^ x[3] ^ x[4] ^ x[7];
  end
endmodule


//Multiply x by alpha^{43}
module rs_syn_mult_s8(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[4] ^ x[6];
    y[1] = x[0] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[4] ^ x[5] ^ x[7];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[6];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6] ^ x[7];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
    y[6] = x[2] ^ x[3] ^ x[4] ^ x[5];
    y[7] = x[3] ^ x[5];
  end
endmodule


//Multiply x by alpha^{45}
module rs_syn_mult_s9(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[2] ^ x[4];
    y[1] = x[2] ^ x[3] ^ x[4] ^ x[5];
    y[2] = x[2] ^ x[3] ^ x[5] ^ x[6];
    y[3] = x[0] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[4] = x[0] ^ x[1] ^ x[4] ^ x[5] ^ x[7];
    y[5] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[6];
    y[6] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6] ^ x[7];
    y[7] = x[1] ^ x[3] ^ x[7];
  end
endmodule


//Multiply x by alpha^{56}
module rs_syn_mult_s10(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[3] ^ x[5] ^ x[7];
    y[1] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[5] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[6] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[7] = x[2] ^ x[4] ^ x[6];
  end
endmodule


//Multiply x by alpha^{67}
module rs_syn_mult_s11(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[5] ^ x[7];
    y[1] = x[1] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[4] ^ x[5] ^ x[6];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[6] ^ x[7];
    y[4] = x[1] ^ x[2] ^ x[3] ^ x[6] ^ x[7];
    y[5] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
    y[6] = x[1] ^ x[3] ^ x[4] ^ x[5];
    y[7] = x[0] ^ x[1] ^ x[4] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{78}
module rs_syn_mult_s12(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[4] ^ x[5] ^ x[6];
    y[1] = x[0] ^ x[1] ^ x[4] ^ x[7];
    y[2] = x[1] ^ x[2] ^ x[4] ^ x[6];
    y[3] = x[2] ^ x[3] ^ x[5] ^ x[7];
    y[4] = x[0] ^ x[3] ^ x[4] ^ x[6];
    y[5] = x[1] ^ x[4] ^ x[5] ^ x[7];
    y[6] = x[2] ^ x[5] ^ x[6];
    y[7] = x[3] ^ x[4] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{89}
module rs_syn_mult_s13(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[1] = x[1] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5];
    y[3] = x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
    y[4] = x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[5] = x[3] ^ x[4] ^ x[6] ^ x[7];
    y[6] = x[4] ^ x[5] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{100}
module rs_syn_mult_s14(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[6];
    y[1] = x[0] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[6] ^ x[7];
    y[3] = x[1] ^ x[2] ^ x[7];
    y[4] = x[2] ^ x[3];
    y[5] = x[3] ^ x[4];
    y[6] = x[4] ^ x[5];
    y[7] = x[5];
  end
endmodule


//Multiply x by alpha^{111}
module rs_syn_mult_s15(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[1] = x[1] ^ x[2] ^ x[3] ^ x[7];
    y[2] = x[1] ^ x[2] ^ x[5] ^ x[6];
    y[3] = x[2] ^ x[3] ^ x[6] ^ x[7];
    y[4] = x[3] ^ x[4] ^ x[7];
    y[5] = x[0] ^ x[4] ^ x[5];
    y[6] = x[0] ^ x[1] ^ x[5] ^ x[6];
    y[7] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{122}
module rs_syn_mult_s16(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[3] ^ x[4];
    y[1] = x[0] ^ x[1] ^ x[5];
    y[2] = x[3] ^ x[4] ^ x[6];
    y[3] = x[0] ^ x[4] ^ x[5] ^ x[7];
    y[4] = x[1] ^ x[5] ^ x[6];
    y[5] = x[2] ^ x[6] ^ x[7];
    y[6] = x[3] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[3];
  end
endmodule


//Multiply x by alpha^{133}
module rs_syn_mult_s17(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
    y[1] = x[1] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[3] ^ x[6];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[7];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
    y[6] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{144}
module rs_syn_mult_s18(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
    y[1] = x[1] ^ x[5] ^ x[7];
    y[2] = x[1] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[3] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[7];
    y[4] = x[1] ^ x[3] ^ x[5] ^ x[6];
    y[5] = x[2] ^ x[4] ^ x[6] ^ x[7];
    y[6] = x[3] ^ x[5] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{155}
module rs_syn_mult_s19(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[1] = x[1] ^ x[2];
    y[2] = x[4] ^ x[5] ^ x[6] ^ x[7];
    y[3] = x[5] ^ x[6] ^ x[7];
    y[4] = x[6] ^ x[7];
    y[5] = x[7];
    y[6] = x[0];
    y[7] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
  end
endmodule


//Multiply x by alpha^{166}
module rs_syn_mult_s20(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
    y[1] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
    y[2] = x[1] ^ x[3] ^ x[6];
    y[3] = x[2] ^ x[4] ^ x[7];
    y[4] = x[0] ^ x[3] ^ x[5];
    y[5] = x[0] ^ x[1] ^ x[4] ^ x[6];
    y[6] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[7];
    y[7] = x[1] ^ x[3] ^ x[4] ^ x[5];
  end
endmodule


//Multiply x by alpha^{177}
module rs_syn_mult_s21(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[3] ^ x[6] ^ x[7];
    y[1] = x[1] ^ x[3] ^ x[4] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[3] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[4] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[5] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[6] = x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
    y[7] = x[2] ^ x[5] ^ x[6];
  end
endmodule


//Multiply x by alpha^{188}
module rs_syn_mult_s22(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[5] ^ x[6];
    y[1] = x[0] ^ x[1] ^ x[5] ^ x[7];
    y[2] = x[1] ^ x[2] ^ x[5];
    y[3] = x[0] ^ x[2] ^ x[3] ^ x[6];
    y[4] = x[1] ^ x[3] ^ x[4] ^ x[7];
    y[5] = x[2] ^ x[4] ^ x[5];
    y[6] = x[3] ^ x[5] ^ x[6];
    y[7] = x[4] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{199}
module rs_syn_mult_s23(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[5] ^ x[6];
    y[1] = x[0] ^ x[5] ^ x[7];
    y[2] = x[1] ^ x[5];
    y[3] = x[0] ^ x[2] ^ x[6];
    y[4] = x[1] ^ x[3] ^ x[7];
    y[5] = x[2] ^ x[4];
    y[6] = x[3] ^ x[5];
    y[7] = x[4] ^ x[5];
  end
endmodule


//Multiply x by alpha^{210}
module rs_syn_mult_s24(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[1] ^ x[2] ^ x[6] ^ x[7];
    y[1] = x[0] ^ x[3] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[4] ^ x[6];
    y[3] = x[1] ^ x[3] ^ x[5] ^ x[7];
    y[4] = x[2] ^ x[4] ^ x[6];
    y[5] = x[0] ^ x[3] ^ x[5] ^ x[7];
    y[6] = x[1] ^ x[4] ^ x[6];
    y[7] = x[0] ^ x[1] ^ x[5] ^ x[6];
  end
endmodule


//Multiply x by alpha^{212}
module rs_syn_mult_s25(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[4] ^ x[5];
    y[1] = x[1] ^ x[4] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[4] ^ x[7];
    y[3] = x[1] ^ x[3] ^ x[5];
    y[4] = x[0] ^ x[2] ^ x[4] ^ x[6];
    y[5] = x[1] ^ x[3] ^ x[5] ^ x[7];
    y[6] = x[2] ^ x[4] ^ x[6];
    y[7] = x[3] ^ x[4] ^ x[7];
  end
endmodule


//Multiply x by alpha^{221}
module rs_syn_mult_s26(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[4];
    y[1] = x[1] ^ x[4] ^ x[5];
    y[2] = x[2] ^ x[4] ^ x[5] ^ x[6];
    y[3] = x[0] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[4] = x[0] ^ x[1] ^ x[4] ^ x[6] ^ x[7];
    y[5] = x[1] ^ x[2] ^ x[5] ^ x[7];
    y[6] = x[2] ^ x[3] ^ x[6];
    y[7] = x[3] ^ x[7];
  end
endmodule


//Multiply x by alpha^{223}
module rs_syn_mult_s27(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[2] ^ x[6] ^ x[7];
    y[1] = x[2] ^ x[3] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
    y[3] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[4] = x[2] ^ x[4] ^ x[5] ^ x[6];
    y[5] = x[0] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    y[6] = x[0] ^ x[1] ^ x[4] ^ x[6] ^ x[7];
    y[7] = x[1] ^ x[5] ^ x[6];
  end
endmodule


//Multiply x by alpha^{232}
module rs_syn_mult_s28(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[1] = x[0] ^ x[1] ^ x[3] ^ x[7];
    y[2] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6];
    y[3] = x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[4] = x[3] ^ x[4] ^ x[5] ^ x[7];
    y[5] = x[0] ^ x[4] ^ x[5] ^ x[6];
    y[6] = x[1] ^ x[5] ^ x[6] ^ x[7];
    y[7] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{234}
module rs_syn_mult_s29(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
    y[1] = x[1] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[7];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5];
    y[4] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6];
    y[5] = x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[6] = x[3] ^ x[4] ^ x[5] ^ x[7];
    y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5];
  end
endmodule


//Multiply x by alpha^{243}
module rs_syn_mult_s30(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[4] ^ x[6];
    y[1] = x[0] ^ x[1] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    y[2] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[7];
    y[3] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[5] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
    y[6] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[7] = x[3] ^ x[5] ^ x[7];
  end
endmodule


//Multiply x by alpha^{245}
module rs_syn_mult_s31(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[2] ^ x[4] ^ x[6] ^ x[7];
    y[1] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    y[2] = x[0] ^ x[2] ^ x[3] ^ x[5];
    y[3] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[6];
    y[4] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[7];
    y[5] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6];
    y[6] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
    y[7] = x[1] ^ x[3] ^ x[5] ^ x[6];
  end
endmodule


//Multiply x by alpha^{254}
module rs_syn_mult_s32(
  input wire [7:0] x,
  output logic [7:0] y
  );
  always_comb begin
    y[0] = x[0] ^ x[1];
    y[1] = x[0] ^ x[2];
    y[2] = x[3];
    y[3] = x[4];
    y[4] = x[5];
    y[5] = x[6];
    y[6] = x[0] ^ x[7];
    y[7] = x[0];
  end
endmodule

`default_nettype wire
