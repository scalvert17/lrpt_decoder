`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

/*
The rs_error_polynomial module will take in all the syndromes and find the
error location polynomial Lambda(x)
*/

module rs_error_polynomial #(parameter NUM_OF_PARITY_BITS = 32)
  (
  input wire clk_in,
  input wire rst_in,
  input wire new_cvcdu,
  input wire [7:0] syndrome [31:0],  //syndrome polynomial; s[0] = s_0
  input wire data_valid_in,
  output logic [7:0] lambda [16:0],  //1 + 16 coeff error location polynomial big_lambda(x);
  output logic data_valid_out
  );
  localparam POLY_LENGTH = 17;

  enum {IDLE,                //0
        INCR_DELTA_R,        //1
        COMP_DELTA_R,        //2
        SHIFT_B,             //3
        COMP_T_POLY,         //4
        UPDATE_LAM,          //5
        NORMALIZE} state;    //6

  logic [7:0] b_poly [16:0];  //1 + 16 coeff polynomial B(x)
  logic [7:0] t_poly [16:0];  //1 + 16 coeff polynomial T(x)
  logic [5:0] r_count;         //at most 32
  logic [7:0] delta_r;   //i think delta_r is an element (8-bits)
  logic [5:0] l_count;   //idk
  logic [4:0] counter;

  logic [7:0] b_poly_delta_r [16:0];  //product of b_poly and delta_r
  logic [7:0] mult_in1, mult_in2, mult_out;

  rs_multiply rs_multiply_inst (
    .clk_in(clk_in),
    .a(mult_in1),
    .b(mult_in2),
    .y(mult_out)
  );


  logic [7:0] inv_in;
  logic [7:0] inv_out;

  rs_inverse rs_inverse_inst (
    .clk_in(clk_in),
    .x(delta_r),
    .y(inv_out)
  );


  /*
  ///////////////////////
  // FOR TESTING /////////////
  logic [7:0] s0;
  logic [7:0] s1; 
  logic [7:0] s2; 
  logic [7:0] s3; 
  logic [7:0] s4; 
  logic [7:0] s5; 
  logic [7:0] s6; 
  logic [7:0] s7; 
  logic [7:0] s8; 
  logic [7:0] s9; 
  logic [7:0] s10;
  logic [7:0] s11;
  logic [7:0] s12;
  logic [7:0] s13;
  logic [7:0] s14;
  logic [7:0] s15;
  logic [7:0] s16;
  logic [7:0] s17;
  logic [7:0] s18;
  logic [7:0] s19;
  logic [7:0] s20;
  logic [7:0] s21;
  logic [7:0] s22;
  logic [7:0] s23;
  logic [7:0] s24;
  logic [7:0] s25;
  logic [7:0] s26;
  logic [7:0] s27;
  logic [7:0] s28;
  logic [7:0] s29;
  logic [7:0] s30;
  logic [7:0] s31;

  logic [7:0] lambda0;
  logic [7:0] lambda1;
  logic [7:0] lambda2;
  logic [7:0] lambda3;
  logic [7:0] lambda4;
  logic [7:0] lambda5;
  logic [7:0] lambda6;
  logic [7:0] lambda7;
  logic [7:0] lambda8;
  logic [7:0] lambda9;
  logic [7:0] lambda10;
  logic [7:0] lambda11;
  logic [7:0] lambda12;
  logic [7:0] lambda13;
  logic [7:0] lambda14;
  logic [7:0] lambda15;
  logic [7:0] lambda16;

  logic [7:0] b_poly0;
  logic [7:0] b_poly1;
  logic [7:0] b_poly2;
  logic [7:0] b_poly3;
  logic [7:0] b_poly4;
  logic [7:0] b_poly5;
  logic [7:0] b_poly6;
  logic [7:0] b_poly7;
  logic [7:0] b_poly8;
  logic [7:0] b_poly9;
  logic [7:0] b_poly10;
  logic [7:0] b_poly11;
  logic [7:0] b_poly12;
  logic [7:0] b_poly13;
  logic [7:0] b_poly14;
  logic [7:0] b_poly15;
  logic [7:0] b_poly16;

  logic [7:0] b_poly_delta_r0;
  logic [7:0] b_poly_delta_r1;
  logic [7:0] b_poly_delta_r2;
  logic [7:0] b_poly_delta_r3;
  logic [7:0] b_poly_delta_r4;
  logic [7:0] b_poly_delta_r5;
  logic [7:0] b_poly_delta_r6;
  logic [7:0] b_poly_delta_r7;
  logic [7:0] b_poly_delta_r8;
  logic [7:0] b_poly_delta_r9;
  logic [7:0] b_poly_delta_r10;
  logic [7:0] b_poly_delta_r11;
  logic [7:0] b_poly_delta_r12;
  logic [7:0] b_poly_delta_r13;
  logic [7:0] b_poly_delta_r14;
  logic [7:0] b_poly_delta_r15;
  logic [7:0] b_poly_delta_r16;

  logic [7:0] t_poly0;
  logic [7:0] t_poly1;
  logic [7:0] t_poly2;
  logic [7:0] t_poly3;
  logic [7:0] t_poly4;
  logic [7:0] t_poly5;
  logic [7:0] t_poly6;
  logic [7:0] t_poly7;
  logic [7:0] t_poly8;
  logic [7:0] t_poly9;
  logic [7:0] t_poly10;
  logic [7:0] t_poly11;
  logic [7:0] t_poly12;
  logic [7:0] t_poly13;
  logic [7:0] t_poly14;
  logic [7:0] t_poly15;
  logic [7:0] t_poly16;

  always_comb begin
    s0 = syndrome[0];
    s1 = syndrome[1];
    s2 = syndrome[2];
    s3 = syndrome[3];
    s4 = syndrome[4];
    s5 = syndrome[5];
    s6 = syndrome[6];
    s7 = syndrome[7];
    s8 = syndrome[8];
    s9 = syndrome[9];
    s10 = syndrome[10];
    s11 = syndrome[11];
    s12 = syndrome[12];
    s13 = syndrome[13];
    s14 = syndrome[14];
    s15 = syndrome[15];
    s16 = syndrome[16];
    s17 = syndrome[17];
    s18 = syndrome[18];
    s19 = syndrome[19];
    s20 = syndrome[20];
    s21 = syndrome[21];
    s22 = syndrome[22];
    s23 = syndrome[23];
    s24 = syndrome[24];
    s25 = syndrome[25];
    s26 = syndrome[26];
    s27 = syndrome[27];
    s28 = syndrome[28];
    s29 = syndrome[29];
    s30 = syndrome[30];
    s31 = syndrome[31];

    lambda0 = lambda[0];
    lambda1 = lambda[1];
    lambda2 = lambda[2];
    lambda3 = lambda[3];
    lambda4 = lambda[4];
    lambda5 = lambda[5];
    lambda6 = lambda[6];
    lambda7 = lambda[7];
    lambda8 = lambda[8];
    lambda9 = lambda[9];
    lambda10 = lambda[10];
    lambda11 = lambda[11];
    lambda12 = lambda[12];
    lambda13 = lambda[13];
    lambda14 = lambda[14];
    lambda15 = lambda[15];
    lambda16 = lambda[16];

    b_poly0 = b_poly[0];
    b_poly1 = b_poly[1];
    b_poly2 = b_poly[2];
    b_poly3 = b_poly[3];
    b_poly4 = b_poly[4];
    b_poly5 = b_poly[5];
    b_poly6 = b_poly[6];
    b_poly7 = b_poly[7];
    b_poly8 = b_poly[8];
    b_poly9 = b_poly[9];
    b_poly10 = b_poly[10];
    b_poly11 = b_poly[11];
    b_poly12 = b_poly[12];
    b_poly13 = b_poly[13];
    b_poly14 = b_poly[14];
    b_poly15 = b_poly[15];
    b_poly16 = b_poly[16];

    b_poly_delta_r0 = b_poly_delta_r[0];
    b_poly_delta_r1 = b_poly_delta_r[1];
    b_poly_delta_r2 = b_poly_delta_r[2];
    b_poly_delta_r3 = b_poly_delta_r[3];
    b_poly_delta_r4 = b_poly_delta_r[4];
    b_poly_delta_r5 = b_poly_delta_r[5];
    b_poly_delta_r6 = b_poly_delta_r[6];
    b_poly_delta_r7 = b_poly_delta_r[7];
    b_poly_delta_r8 = b_poly_delta_r[8];
    b_poly_delta_r9 = b_poly_delta_r[9];
    b_poly_delta_r10 = b_poly_delta_r[10];
    b_poly_delta_r11 = b_poly_delta_r[11];
    b_poly_delta_r12 = b_poly_delta_r[12];
    b_poly_delta_r13 = b_poly_delta_r[13];
    b_poly_delta_r14 = b_poly_delta_r[14];
    b_poly_delta_r15 = b_poly_delta_r[15];
    b_poly_delta_r16 = b_poly_delta_r[16];

    t_poly0 = t_poly[0];
    t_poly1 = t_poly[1];
    t_poly2 = t_poly[2];
    t_poly3 = t_poly[3];
    t_poly4 = t_poly[4];
    t_poly5 = t_poly[5];
    t_poly6 = t_poly[6];
    t_poly7 = t_poly[7];
    t_poly8 = t_poly[8];
    t_poly9 = t_poly[9];
    t_poly10 = t_poly[10];
    t_poly11 = t_poly[11];
    t_poly12 = t_poly[12];
    t_poly13 = t_poly[13];
    t_poly14 = t_poly[14];
    t_poly15 = t_poly[15];
    t_poly16 = t_poly[16];
  end
  */


  always @(posedge clk_in) begin
    if (rst_in) begin
      for (int i=0; i<17; i=i+1) begin
        lambda[i] <= 0;
        b_poly[i] <= 0;
      end
      r_count <= 0;
      l_count <= 0;
      state <= IDLE;

    
    end else begin
      case(state)



        //DONE******************
        IDLE: begin  //0
          for (int i=0; i<POLY_LENGTH; i=i+1) begin
            lambda[i] <= 1;
            b_poly[i] <= 1;
            t_poly[i] <= 0;
            b_poly_delta_r[i] <= 0;
          end 
          r_count <= 0;
          delta_r <= 0;
          l_count <= 0;
          counter <= 0;
          mult_in1 <= 0;
          mult_in2 <= 0;
          state <= ((new_cvcdu==1) && (data_valid_in==1)) ? INCR_DELTA_R : IDLE;  //begin Berle-Mass at new CVCDU 
          //state <= 3'b001;
        end



        //DONE*****************
        //Increment r
        INCR_DELTA_R: begin  //1
          r_count = r_count + 1;
          state <= COMP_DELTA_R;

          //Load multiplier for COMP_DELTA_R
          mult_in1 <= lambda[0];  //j=0
          mult_in2 <= syndrome[r_count - 1];  //j=0
        end


        //DONE*****************
        //delta_r = sum[j(0 -> l_count)] lambda[j] * S[r-1-j]
        COMP_DELTA_R: begin  //2

          //Must wait one cycle for mult_out; mult_ins loaded in prev state
          //j=counter+1
          if (counter == 0) begin
            delta_r <= 0;  //reset delta_r
            mult_in1 <= lambda[counter + 1];
            mult_in2 <= syndrome[r_count - 2 - counter];
            counter <= counter + 1;

          end else if (counter <= (l_count+1)) begin
            delta_r <= delta_r ^ mult_out;
            mult_in1 <= lambda[counter + 1];
            mult_in2 <= syndrome[r_count - 2 - counter];
            counter <= counter + 1;

          end else begin
            state <= (delta_r == 0) ? SHIFT_B : COMP_T_POLY;
            counter <= 0;

            //Load multiplier for COMP_T_POLY
            mult_in1 <= delta_r;
            mult_in2 <= b_poly[0];
          end
        end



        //DONE*********************
        //b_poly <= x*b_poly; think this would be equal to shifting the whole array
        SHIFT_B: begin  //3
          for (int i=0; i<POLY_LENGTH; i=i+1) begin
            b_poly[i+1] <= b_poly[i];
          end

          state <= (r_count == NUM_OF_PARITY_BITS) ? IDLE : INCR_DELTA_R;
        end



        //<j:0->POLY_LENGTH> T[j] <= lambda[j] + delta * x * b_poly[j]
        COMP_T_POLY: begin  //4

          //Must wait one cycle for mult_out; mult_ins loaded in COMP_DELTA_R
          //j=counter+1
          if (counter == 0) begin
            mult_in1 <= delta_r;
            mult_in2 <= b_poly[counter + 1];
            counter <= counter + 1;
            b_poly_delta_r[counter] <= 0;

          //Compute delta*x*b(x); delta*b_poly[0] = b_poly_delta_r[1]
          end else if (counter < POLY_LENGTH) begin
            mult_in1 <= delta_r;
            mult_in2 <= b_poly[counter + 1];
            counter <= counter + 1;
            b_poly_delta_r[counter] <= mult_out;

          //lambda - b_poly_delta_r
          end else if (counter == POLY_LENGTH) begin
            for (int i=0; i<POLY_LENGTH; i=i+1) begin
              t_poly[i] <= lambda[i] ^ b_poly_delta_r[i];
            end
            counter <= counter + 1;

          //End; move to next state
          end else begin
            counter <= 0;
            state <= ((2*l_count) > (r_count-1)) ? UPDATE_LAM : NORMALIZE;

            //Preload multiplier for NORMALIZE
            mult_in1 <= inv_out;
            mult_in2 <= lambda[0];
          end
        end



        //DONE*****************
        UPDATE_LAM: begin  //5
          //lambda <= T
          //b_poly <= x*b_poly
          for (int i=0; i<POLY_LENGTH; i=i+1) begin
            lambda[i] <= t_poly[i];
            b_poly[i+1] <= b_poly[i];
          end
          b_poly[0] <= 0;

          state <= (r_count == NUM_OF_PARITY_BITS) ? IDLE : INCR_DELTA_R;
        end



        NORMALIZE: begin  //6
          //Must wait one cycle for mult_out; mult_ins loaded in prev cycle
          //b <= delta^{-1} * lambda
          if (counter == 0) begin
            mult_in1 <= inv_out;
            mult_in2 <= lambda[counter + 1];
            counter <= counter + 1;

          //Same as above but mult_out is valid
          end else if (counter <= POLY_LENGTH) begin
            b_poly[counter - 1] <= mult_out;
            mult_in1 <= inv_out;
            mult_in2 <= lambda[counter + 1];
            counter <= counter + 1;

          //lambda <= T
          //l <= r - lambda
          end else begin
            for (int i=0; i<POLY_LENGTH; i=i+1) begin
              lambda[i] <= t_poly[i];
            end
            l_count <= r_count - l_count;
            state <= (r_count == NUM_OF_PARITY_BITS) ? IDLE : INCR_DELTA_R;
            counter <= 0;
          end

        end
      endcase
    end
  end
endmodule  //rs_error_polynomial



///////////////////////////////
// GF(2^8) Multiply
//   Returns the product of two GF(2^8) elements a*b=y
module rs_multiply(
  input wire clk_in,
  input wire [7:0] a,
  input wire [7:0] b,
  output logic [7:0] y
  );

  always @(posedge clk_in) begin
    y[0] <= (a[0] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ (a[3] & b[5]) ^ (a[4] & b[4]) ^ 
            (a[5] & b[3]) ^ (a[6] & b[2]) ^ (a[7] & b[1]) ^ (a[2] & b[7]) ^ (a[3] & b[6]) ^ 
            (a[4] & b[5]) ^ (a[5] & b[4]) ^ (a[6] & b[3]) ^ (a[7] & b[2]) ^ (a[3] & b[7]) ^ 
            (a[4] & b[6]) ^ (a[5] & b[5]) ^ (a[6] & b[4]) ^ (a[7] & b[3]) ^ (a[4] & b[7]) ^ 
            (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[7] & b[4]) ^ (a[5] & b[7]) ^ (a[6] & b[6]) ^ 
            (a[7] & b[5]) ^ (a[6] & b[7]) ^ (a[7] & b[6]);

    y[1] <= (a[0] & b[1]) ^ (a[1] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ (a[3] & b[5]) ^ 
            (a[4] & b[4]) ^ (a[5] & b[3]) ^ (a[6] & b[2]) ^ (a[7] & b[1]) ^ (a[7] & b[7]);
    
    y[2] <= (a[0] & b[2]) ^ (a[1] & b[1]) ^ (a[2] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ 
            (a[3] & b[5]) ^ (a[4] & b[4]) ^ (a[5] & b[3]) ^ (a[6] & b[2]) ^ (a[7] & b[1]) ^ 
            (a[3] & b[7]) ^ (a[4] & b[6]) ^ (a[5] & b[5]) ^ (a[6] & b[4]) ^ (a[7] & b[3]) ^ 
            (a[4] & b[7]) ^ (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[7] & b[4]) ^ (a[5] & b[7]) ^ 
            (a[6] & b[6]) ^ (a[7] & b[5]) ^ (a[6] & b[7]) ^ (a[7] & b[6]);

    y[3] <= (a[0] & b[3]) ^ (a[1] & b[2]) ^ (a[2] & b[1]) ^ (a[3] & b[0]) ^ (a[2] & b[7]) ^ 
            (a[3] & b[6]) ^ (a[4] & b[5]) ^ (a[5] & b[4]) ^ (a[6] & b[3]) ^ (a[7] & b[2]) ^ 
            (a[4] & b[7]) ^ (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[7] & b[4]) ^ (a[5] & b[7]) ^ 
            (a[6] & b[6]) ^ (a[7] & b[5]) ^ (a[6] & b[7]) ^ (a[7] & b[6]) ^ (a[7] & b[7]);

    y[4] <= (a[0] & b[4]) ^ (a[1] & b[3]) ^ (a[2] & b[2]) ^ (a[3] & b[1]) ^ (a[4] & b[0]) ^ 
            (a[3] & b[7]) ^ (a[4] & b[6]) ^ (a[5] & b[5]) ^ (a[6] & b[4]) ^ (a[7] & b[3]) ^ 
            (a[5] & b[7]) ^ (a[6] & b[6]) ^ (a[7] & b[5]) ^ (a[6] & b[7]) ^ (a[7] & b[6]) ^ 
            (a[7] & b[7]);
    
    y[5] <= (a[0] & b[5]) ^ (a[1] & b[4]) ^ (a[2] & b[3]) ^ (a[3] & b[2]) ^ (a[4] & b[1]) ^ 
            (a[5] & b[0]) ^ (a[4] & b[7]) ^ (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[7] & b[4]) ^ 
            (a[6] & b[7]) ^ (a[7] & b[6]) ^ (a[7] & b[7]);
    
    y[6] <= (a[0] & b[6]) ^ (a[1] & b[5]) ^ (a[2] & b[4]) ^ (a[3] & b[3]) ^ (a[4] & b[2]) ^ 
            (a[5] & b[1]) ^ (a[6] & b[0]) ^ (a[5] & b[7]) ^ (a[6] & b[6]) ^ (a[7] & b[5]) ^ 
            (a[7] & b[7]);
    
    y[7] <= (a[0] & b[7]) ^ (a[1] & b[6]) ^ (a[2] & b[5]) ^ (a[3] & b[4]) ^ (a[4] & b[3]) ^ 
            (a[5] & b[2]) ^ (a[6] & b[1]) ^ (a[7] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ 
            (a[3] & b[5]) ^ (a[4] & b[4]) ^ (a[5] & b[3]) ^ (a[6] & b[2]) ^ (a[7] & b[1]) ^ 
            (a[2] & b[7]) ^ (a[3] & b[6]) ^ (a[4] & b[5]) ^ (a[5] & b[4]) ^ (a[6] & b[3]) ^ 
            (a[7] & b[2]) ^ (a[3] & b[7]) ^ (a[4] & b[6]) ^ (a[5] & b[5]) ^ (a[6] & b[4]) ^ 
            (a[7] & b[3]) ^ (a[4] & b[7]) ^ (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[7] & b[4]) ^ 
            (a[5] & b[7]) ^ (a[6] & b[6]) ^ (a[7] & b[5]);
  end
endmodule  //rs_multiply



///////////////////////////////
// GF(2^8) Inverse
//   Returns the inverse of the input element x.
//   x and y are elements of GF(2^8) described by x^8 + x^7 + x^2 + x + 1
module rs_inverse(
  input wire clk_in,
  input wire [7:0] x,
  output logic [7:0] y
  );
  
  always @(posedge clk_in) begin
    case(x)
      1   : y = 1;     //x=[alpha^0]    y=[alpha^0]
      2   : y = 195;   //x=[alpha^1]    y=[alpha^254]
      4   : y = 162;   //x=[alpha^2]    y=[alpha^253]
      8   : y = 81;    //x=[alpha^3]    y=[alpha^252]
      16  : y = 235;   //x=[alpha^4]    y=[alpha^251]
      32  : y = 182;   //x=[alpha^5]    y=[alpha^250]
      64  : y = 91;    //x=[alpha^6]    y=[alpha^249]
      128 : y = 238;   //x=[alpha^7]    y=[alpha^248]
      135 : y = 119;   //x=[alpha^8]    y=[alpha^247]
      137 : y = 248;   //x=[alpha^9]    y=[alpha^246]
      149 : y = 124;   //x=[alpha^10]    y=[alpha^245]
      173 : y = 62;    //x=[alpha^11]    y=[alpha^244]
      221 : y = 31;    //x=[alpha^12]    y=[alpha^243]
      61  : y = 204;   //x=[alpha^13]    y=[alpha^242]
      122 : y = 102;   //x=[alpha^14]    y=[alpha^241]
      244 : y = 51;    //x=[alpha^15]    y=[alpha^240]
      111 : y = 218;   //x=[alpha^16]    y=[alpha^239]
      222 : y = 109;   //x=[alpha^17]    y=[alpha^238]
      59  : y = 245;   //x=[alpha^18]    y=[alpha^237]
      118 : y = 185;   //x=[alpha^19]    y=[alpha^236]
      236 : y = 159;   //x=[alpha^20]    y=[alpha^235]
      95  : y = 140;   //x=[alpha^21]    y=[alpha^234]
      190 : y = 70;    //x=[alpha^22]    y=[alpha^233]
      251 : y = 35;    //x=[alpha^23]    y=[alpha^232]
      113 : y = 210;   //x=[alpha^24]    y=[alpha^231]
      226 : y = 105;   //x=[alpha^25]    y=[alpha^230]
      67  : y = 247;   //x=[alpha^26]    y=[alpha^229]
      134 : y = 184;   //x=[alpha^27]    y=[alpha^228]
      139 : y = 92;    //x=[alpha^28]    y=[alpha^227]
      145 : y = 46;    //x=[alpha^29]    y=[alpha^226]
      165 : y = 23;    //x=[alpha^30]    y=[alpha^225]
      205 : y = 200;   //x=[alpha^31]    y=[alpha^224]
      29  : y = 100;   //x=[alpha^32]    y=[alpha^223]
      58  : y = 50;    //x=[alpha^33]    y=[alpha^222]
      116 : y = 25;    //x=[alpha^34]    y=[alpha^221]
      232 : y = 207;   //x=[alpha^35]    y=[alpha^220]
      87  : y = 164;   //x=[alpha^36]    y=[alpha^219]
      174 : y = 82;    //x=[alpha^37]    y=[alpha^218]
      219 : y = 41;    //x=[alpha^38]    y=[alpha^217]
      49  : y = 215;   //x=[alpha^39]    y=[alpha^216]
      98  : y = 168;   //x=[alpha^40]    y=[alpha^215]
      196 : y = 84;    //x=[alpha^41]    y=[alpha^214]
      15  : y = 42;    //x=[alpha^42]    y=[alpha^213]
      30  : y = 21;    //x=[alpha^43]    y=[alpha^212]
      60  : y = 201;   //x=[alpha^44]    y=[alpha^211]
      120 : y = 167;   //x=[alpha^45]    y=[alpha^210]
      240 : y = 144;   //x=[alpha^46]    y=[alpha^209]
      103 : y = 72;    //x=[alpha^47]    y=[alpha^208]
      206 : y = 36;    //x=[alpha^48]    y=[alpha^207]
      27  : y = 18;    //x=[alpha^49]    y=[alpha^206]
      54  : y = 9;     //x=[alpha^50]    y=[alpha^205]
      108 : y = 199;   //x=[alpha^51]    y=[alpha^204]
      216 : y = 160;   //x=[alpha^52]    y=[alpha^203]
      55  : y = 80;    //x=[alpha^53]    y=[alpha^202]
      110 : y = 40;    //x=[alpha^54]    y=[alpha^201]
      220 : y = 20;    //x=[alpha^55]    y=[alpha^200]
      63  : y = 10;    //x=[alpha^56]    y=[alpha^199]
      126 : y = 5;     //x=[alpha^57]    y=[alpha^198]
      252 : y = 193;   //x=[alpha^58]    y=[alpha^197]
      127 : y = 163;   //x=[alpha^59]    y=[alpha^196]
      254 : y = 146;   //x=[alpha^60]    y=[alpha^195]
      123 : y = 73;    //x=[alpha^61]    y=[alpha^194]
      246 : y = 231;   //x=[alpha^62]    y=[alpha^193]
      107 : y = 176;   //x=[alpha^63]    y=[alpha^192]
      214 : y = 88;    //x=[alpha^64]    y=[alpha^191]
      43  : y = 44;    //x=[alpha^65]    y=[alpha^190]
      86  : y = 22;    //x=[alpha^66]    y=[alpha^189]
      172 : y = 11;    //x=[alpha^67]    y=[alpha^188]
      223 : y = 198;   //x=[alpha^68]    y=[alpha^187]
      57  : y = 99;    //x=[alpha^69]    y=[alpha^186]
      114 : y = 242;   //x=[alpha^70]    y=[alpha^185]
      228 : y = 121;   //x=[alpha^71]    y=[alpha^184]
      79  : y = 255;   //x=[alpha^72]    y=[alpha^183]
      158 : y = 188;   //x=[alpha^73]    y=[alpha^182]
      187 : y = 94;    //x=[alpha^74]    y=[alpha^181]
      241 : y = 47;    //x=[alpha^75]    y=[alpha^180]
      101 : y = 212;   //x=[alpha^76]    y=[alpha^179]
      202 : y = 106;   //x=[alpha^77]    y=[alpha^178]
      19  : y = 53;    //x=[alpha^78]    y=[alpha^177]
      38  : y = 217;   //x=[alpha^79]    y=[alpha^176]
      76  : y = 175;   //x=[alpha^80]    y=[alpha^175]
      152 : y = 148;   //x=[alpha^81]    y=[alpha^174]
      183 : y = 74;    //x=[alpha^82]    y=[alpha^173]
      233 : y = 37;    //x=[alpha^83]    y=[alpha^172]
      85  : y = 209;   //x=[alpha^84]    y=[alpha^171]
      170 : y = 171;   //x=[alpha^85]    y=[alpha^170]
      211 : y = 150;   //x=[alpha^86]    y=[alpha^169]
      33  : y = 75;    //x=[alpha^87]    y=[alpha^168]
      66  : y = 230;   //x=[alpha^88]    y=[alpha^167]
      132 : y = 115;   //x=[alpha^89]    y=[alpha^166]
      143 : y = 250;   //x=[alpha^90]    y=[alpha^165]
      153 : y = 125;   //x=[alpha^91]    y=[alpha^164]
      181 : y = 253;   //x=[alpha^92]    y=[alpha^163]
      237 : y = 189;   //x=[alpha^93]    y=[alpha^162]
      93  : y = 157;   //x=[alpha^94]    y=[alpha^161]
      186 : y = 141;   //x=[alpha^95]    y=[alpha^160]
      243 : y = 133;   //x=[alpha^96]    y=[alpha^159]
      97  : y = 129;   //x=[alpha^97]    y=[alpha^158]
      194 : y = 131;   //x=[alpha^98]    y=[alpha^157]
      3   : y = 130;   //x=[alpha^99]    y=[alpha^156]
      6   : y = 65;    //x=[alpha^100]    y=[alpha^155]
      12  : y = 227;   //x=[alpha^101]    y=[alpha^154]
      24  : y = 178;   //x=[alpha^102]    y=[alpha^153]
      48  : y = 89;    //x=[alpha^103]    y=[alpha^152]
      96  : y = 239;   //x=[alpha^104]    y=[alpha^151]
      192 : y = 180;   //x=[alpha^105]    y=[alpha^150]
      7   : y = 90;    //x=[alpha^106]    y=[alpha^149]
      14  : y = 45;    //x=[alpha^107]    y=[alpha^148]
      28  : y = 213;   //x=[alpha^108]    y=[alpha^147]
      56  : y = 169;   //x=[alpha^109]    y=[alpha^146]
      112 : y = 151;   //x=[alpha^110]    y=[alpha^145]
      224 : y = 136;   //x=[alpha^111]    y=[alpha^144]
      71  : y = 68;    //x=[alpha^112]    y=[alpha^143]
      142 : y = 34;    //x=[alpha^113]    y=[alpha^142]
      155 : y = 17;    //x=[alpha^114]    y=[alpha^141]
      177 : y = 203;   //x=[alpha^115]    y=[alpha^140]
      229 : y = 166;   //x=[alpha^116]    y=[alpha^139]
      77  : y = 83;    //x=[alpha^117]    y=[alpha^138]
      154 : y = 234;   //x=[alpha^118]    y=[alpha^137]
      179 : y = 117;   //x=[alpha^119]    y=[alpha^136]
      225 : y = 249;   //x=[alpha^120]    y=[alpha^135]
      69  : y = 191;   //x=[alpha^121]    y=[alpha^134]
      138 : y = 156;   //x=[alpha^122]    y=[alpha^133]
      147 : y = 78;    //x=[alpha^123]    y=[alpha^132]
      161 : y = 39;    //x=[alpha^124]    y=[alpha^131]
      197 : y = 208;   //x=[alpha^125]    y=[alpha^130]
      13  : y = 104;   //x=[alpha^126]    y=[alpha^129]
      26  : y = 52;    //x=[alpha^127]    y=[alpha^128]
      52  : y = 26;    //x=[alpha^128]    y=[alpha^127]
      104 : y = 13;    //x=[alpha^129]    y=[alpha^126]
      208 : y = 197;   //x=[alpha^130]    y=[alpha^125]
      39  : y = 161;   //x=[alpha^131]    y=[alpha^124]
      78  : y = 147;   //x=[alpha^132]    y=[alpha^123]
      156 : y = 138;   //x=[alpha^133]    y=[alpha^122]
      191 : y = 69;    //x=[alpha^134]    y=[alpha^121]
      249 : y = 225;   //x=[alpha^135]    y=[alpha^120]
      117 : y = 179;   //x=[alpha^136]    y=[alpha^119]
      234 : y = 154;   //x=[alpha^137]    y=[alpha^118]
      83  : y = 77;    //x=[alpha^138]    y=[alpha^117]
      166 : y = 229;   //x=[alpha^139]    y=[alpha^116]
      203 : y = 177;   //x=[alpha^140]    y=[alpha^115]
      17  : y = 155;   //x=[alpha^141]    y=[alpha^114]
      34  : y = 142;   //x=[alpha^142]    y=[alpha^113]
      68  : y = 71;    //x=[alpha^143]    y=[alpha^112]
      136 : y = 224;   //x=[alpha^144]    y=[alpha^111]
      151 : y = 112;   //x=[alpha^145]    y=[alpha^110]
      169 : y = 56;    //x=[alpha^146]    y=[alpha^109]
      213 : y = 28;    //x=[alpha^147]    y=[alpha^108]
      45  : y = 14;    //x=[alpha^148]    y=[alpha^107]
      90  : y = 7;     //x=[alpha^149]    y=[alpha^106]
      180 : y = 192;   //x=[alpha^150]    y=[alpha^105]
      239 : y = 96;    //x=[alpha^151]    y=[alpha^104]
      89  : y = 48;    //x=[alpha^152]    y=[alpha^103]
      178 : y = 24;    //x=[alpha^153]    y=[alpha^102]
      227 : y = 12;    //x=[alpha^154]    y=[alpha^101]
      65  : y = 6;     //x=[alpha^155]    y=[alpha^100]
      130 : y = 3;     //x=[alpha^156]    y=[alpha^99]
      131 : y = 194;   //x=[alpha^157]    y=[alpha^98]
      129 : y = 97;    //x=[alpha^158]    y=[alpha^97]
      133 : y = 243;   //x=[alpha^159]    y=[alpha^96]
      141 : y = 186;   //x=[alpha^160]    y=[alpha^95]
      157 : y = 93;    //x=[alpha^161]    y=[alpha^94]
      189 : y = 237;   //x=[alpha^162]    y=[alpha^93]
      253 : y = 181;   //x=[alpha^163]    y=[alpha^92]
      125 : y = 153;   //x=[alpha^164]    y=[alpha^91]
      250 : y = 143;   //x=[alpha^165]    y=[alpha^90]
      115 : y = 132;   //x=[alpha^166]    y=[alpha^89]
      230 : y = 66;    //x=[alpha^167]    y=[alpha^88]
      75  : y = 33;    //x=[alpha^168]    y=[alpha^87]
      150 : y = 211;   //x=[alpha^169]    y=[alpha^86]
      171 : y = 170;   //x=[alpha^170]    y=[alpha^85]
      209 : y = 85;    //x=[alpha^171]    y=[alpha^84]
      37  : y = 233;   //x=[alpha^172]    y=[alpha^83]
      74  : y = 183;   //x=[alpha^173]    y=[alpha^82]
      148 : y = 152;   //x=[alpha^174]    y=[alpha^81]
      175 : y = 76;    //x=[alpha^175]    y=[alpha^80]
      217 : y = 38;    //x=[alpha^176]    y=[alpha^79]
      53  : y = 19;    //x=[alpha^177]    y=[alpha^78]
      106 : y = 202;   //x=[alpha^178]    y=[alpha^77]
      212 : y = 101;   //x=[alpha^179]    y=[alpha^76]
      47  : y = 241;   //x=[alpha^180]    y=[alpha^75]
      94  : y = 187;   //x=[alpha^181]    y=[alpha^74]
      188 : y = 158;   //x=[alpha^182]    y=[alpha^73]
      255 : y = 79;    //x=[alpha^183]    y=[alpha^72]
      121 : y = 228;   //x=[alpha^184]    y=[alpha^71]
      242 : y = 114;   //x=[alpha^185]    y=[alpha^70]
      99  : y = 57;    //x=[alpha^186]    y=[alpha^69]
      198 : y = 223;   //x=[alpha^187]    y=[alpha^68]
      11  : y = 172;   //x=[alpha^188]    y=[alpha^67]
      22  : y = 86;    //x=[alpha^189]    y=[alpha^66]
      44  : y = 43;    //x=[alpha^190]    y=[alpha^65]
      88  : y = 214;   //x=[alpha^191]    y=[alpha^64]
      176 : y = 107;   //x=[alpha^192]    y=[alpha^63]
      231 : y = 246;   //x=[alpha^193]    y=[alpha^62]
      73  : y = 123;   //x=[alpha^194]    y=[alpha^61]
      146 : y = 254;   //x=[alpha^195]    y=[alpha^60]
      163 : y = 127;   //x=[alpha^196]    y=[alpha^59]
      193 : y = 252;   //x=[alpha^197]    y=[alpha^58]
      5   : y = 126;   //x=[alpha^198]    y=[alpha^57]
      10  : y = 63;    //x=[alpha^199]    y=[alpha^56]
      20  : y = 220;   //x=[alpha^200]    y=[alpha^55]
      40  : y = 110;   //x=[alpha^201]    y=[alpha^54]
      80  : y = 55;    //x=[alpha^202]    y=[alpha^53]
      160 : y = 216;   //x=[alpha^203]    y=[alpha^52]
      199 : y = 108;   //x=[alpha^204]    y=[alpha^51]
      9   : y = 54;    //x=[alpha^205]    y=[alpha^50]
      18  : y = 27;    //x=[alpha^206]    y=[alpha^49]
      36  : y = 206;   //x=[alpha^207]    y=[alpha^48]
      72  : y = 103;   //x=[alpha^208]    y=[alpha^47]
      144 : y = 240;   //x=[alpha^209]    y=[alpha^46]
      167 : y = 120;   //x=[alpha^210]    y=[alpha^45]
      201 : y = 60;    //x=[alpha^211]    y=[alpha^44]
      21  : y = 30;    //x=[alpha^212]    y=[alpha^43]
      42  : y = 15;    //x=[alpha^213]    y=[alpha^42]
      84  : y = 196;   //x=[alpha^214]    y=[alpha^41]
      168 : y = 98;    //x=[alpha^215]    y=[alpha^40]
      215 : y = 49;    //x=[alpha^216]    y=[alpha^39]
      41  : y = 219;   //x=[alpha^217]    y=[alpha^38]
      82  : y = 174;   //x=[alpha^218]    y=[alpha^37]
      164 : y = 87;    //x=[alpha^219]    y=[alpha^36]
      207 : y = 232;   //x=[alpha^220]    y=[alpha^35]
      25  : y = 116;   //x=[alpha^221]    y=[alpha^34]
      50  : y = 58;    //x=[alpha^222]    y=[alpha^33]
      100 : y = 29;    //x=[alpha^223]    y=[alpha^32]
      200 : y = 205;   //x=[alpha^224]    y=[alpha^31]
      23  : y = 165;   //x=[alpha^225]    y=[alpha^30]
      46  : y = 145;   //x=[alpha^226]    y=[alpha^29]
      92  : y = 139;   //x=[alpha^227]    y=[alpha^28]
      184 : y = 134;   //x=[alpha^228]    y=[alpha^27]
      247 : y = 67;    //x=[alpha^229]    y=[alpha^26]
      105 : y = 226;   //x=[alpha^230]    y=[alpha^25]
      210 : y = 113;   //x=[alpha^231]    y=[alpha^24]
      35  : y = 251;   //x=[alpha^232]    y=[alpha^23]
      70  : y = 190;   //x=[alpha^233]    y=[alpha^22]
      140 : y = 95;    //x=[alpha^234]    y=[alpha^21]
      159 : y = 236;   //x=[alpha^235]    y=[alpha^20]
      185 : y = 118;   //x=[alpha^236]    y=[alpha^19]
      245 : y = 59;    //x=[alpha^237]    y=[alpha^18]
      109 : y = 222;   //x=[alpha^238]    y=[alpha^17]
      218 : y = 111;   //x=[alpha^239]    y=[alpha^16]
      51  : y = 244;   //x=[alpha^240]    y=[alpha^15]
      102 : y = 122;   //x=[alpha^241]    y=[alpha^14]
      204 : y = 61;    //x=[alpha^242]    y=[alpha^13]
      31  : y = 221;   //x=[alpha^243]    y=[alpha^12]
      62  : y = 173;   //x=[alpha^244]    y=[alpha^11]
      124 : y = 149;   //x=[alpha^245]    y=[alpha^10]
      248 : y = 137;   //x=[alpha^246]    y=[alpha^9]
      119 : y = 135;   //x=[alpha^247]    y=[alpha^8]
      238 : y = 128;   //x=[alpha^248]    y=[alpha^7]
      91  : y = 64;    //x=[alpha^249]    y=[alpha^6]
      182 : y = 32;    //x=[alpha^250]    y=[alpha^5]
      235 : y = 16;    //x=[alpha^251]    y=[alpha^4]
      81  : y = 8;     //x=[alpha^252]    y=[alpha^3]
      162 : y = 4;     //x=[alpha^253]    y=[alpha^2]
      195 : y = 2;     //x=[alpha^254]    y=[alpha^1]
      default : y = 1;
    endcase
  end

endmodule  //rs_inverse

`default_nettype wire