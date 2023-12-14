`timescale 1ns / 1ps
`default_nettype none

module tx_tb();

  logic clk_in;
  logic rst_in;
  logic transmit;
  logic baud_tick;
  logic [7:0] data_in;
  logic busy;
  logic data_out;


  transmitter txd (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .transmit(transmit),
    .data_in(data_in),
    .baud_tick(baud_tick),
    .tx(data_out),
    .tx_busy(busy)
  );

  tick_generator tickgen (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .sample_tick_out(),
  .baud_tick(baud_tick)
);

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("tx.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,tx_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    transmit = 0;
    data_in = 8'hFF;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    transmit = 0;
    data_in = 8'hFF;
    #10000;
    transmit = 1;
    #1000000;
    transmit = 0;
    data_in = 8'hFF;
    #1000000;
    transmit = 1;
    #1000000;
    transmit = 0;

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
