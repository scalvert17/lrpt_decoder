`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)


module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn,
  input wire [15:0] sw,
  output logic [15:0] led,
  output logic uart_txd,
  input wire uart_rxd
);

// Internal signals
logic [7:0] data_recieved;
logic [7:0] data_to_send = 8'h00;
logic valid_received;
logic transmitter_busy;

logic sample_tick;
logic baud_tick;
logic received_bit;
logic transmit;


// Debug
logic prev_valid_recieved;
logic sample_non_zero;


logic sys_rst;
always_comb begin
  sys_rst = btn[0];
end

transmitter tx (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .transmit(transmit),
  .data_in(data_to_send),
  .baud_tick(baud_tick),
  .tx(uart_txd),
  .tx_busy(transmitter_busy)
);

receiver2 rx (
  .i_Clock(clk_100mhz),
  .i_RX_Serial(uart_rxd),
  .o_RX_DV(valid_received),
  .o_RX_Byte(data_recieved),
  .sample_non_zero(sample_non_zero)
);

tick_generator tickgen (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .sample_tick_out(),
  .baud_tick(baud_tick)
);

BaudTickGen samplegen (
  .clk(clk_100mhz),
  .enable(1'b1),
  .tick(sample_tick)
);

always_ff @(posedge clk_100mhz) begin
  prev_valid_recieved <= valid_received;
  if (sys_rst) begin
    led[15:0] <= 0;
    data_to_send <= 8'h00;
    data_recieved <= 8'h00;
  end else if (valid_received && prev_valid_recieved) begin
    led[0] <= 1;
  end else if (valid_received) begin
    led[14] <= 1;
    data_to_send <= data_recieved;
    led[7:0] <= data_recieved;
    transmit <= 1;
  end else begin
    transmit <= sw[15];
    led[13] <= uart_rxd;
  end
  if (data_recieved != 0)begin
    led[2] <= 1;
  end else if (sample_non_zero) begin 
    led[1] <= 1;
  end else led[2] <= 0; 
end

always_comb begin

end


endmodule
`default_nettype wire
