
module tick_generator (
  input wire clk_in, //100MHz
  input wire rst_in,
  output logic sample_tick_out, //16 times per baud tick
  output logic baud_tick
);

  // Internal signals
  logic [17:0] accumulator_tot;
  logic [10:0] accumulator_sample;
  logic sample_tick;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      accumulator_tot <= 0;
      accumulator_sample <= 0;
    end else begin
      accumulator_tot <= accumulator_tot[16:0] + 151;
      accumulator_sample <= accumulator_sample + 4;
      if (accumulator_sample >= 225) begin
          sample_tick <= 1;
          accumulator_sample <= accumulator_sample - 217;
      end
      else begin
          sample_tick <= 0;
      end
    end
  end
  assign baud_tick = accumulator_tot[17];
  assign sample_tick_out = sample_tick;
endmodule

