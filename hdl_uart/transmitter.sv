
module transmitter (
  input wire clk_in,
  input wire rst_in,
  input wire transmit,
  input wire [7:0] data_in,
  input wire baud_tick,
  output logic tx,
  output logic tx_busy
);

  typedef enum {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT
  } state_t;


  state_t state;
  logic [7:0] data;
  logic [3:0] bit_counter;
  logic [3:0] baud_counter;
  logic stop_wait;

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
        state <= IDLE;
        data <= 0;
        bit_counter <= 0;
        baud_counter <= 0;
        tx <= 1'b1;
        tx_busy <= 1'b0;
    end else begin 
        case (state)
      // Wait for transmit request
      IDLE: begin
        tx <= 1'b1;
        tx_busy <= 1'b0;
        if (transmit && baud_tick) begin
          state <= START_BIT;
          data <= data_in;
          bit_counter <= 0;
          tx_busy <= 1'b1;
        end
      end

      // Transmit Start bits
      START_BIT: begin
        tx <= 1'b0; // Start bit
        if (baud_tick) begin
            state <= DATA_BITS;
            bit_counter <= 0;
            tx <= data[bit_counter];
            bit_counter <= bit_counter + 1;
        end 
      end

      // Transmit data bits
      DATA_BITS: begin
        if (baud_tick) begin
            if (bit_counter < 7) begin
                tx <= data[bit_counter];
                bit_counter <= bit_counter + 1;
            end else begin
                tx <= data[bit_counter];
                state <= STOP_BIT;
                stop_wait <= 1'b0;
            end
        end
      end

      // Transmit Stop Bit
      STOP_BIT: begin
        if (baud_tick) begin
            tx <= 1'b1;
            if (stop_wait) state <= IDLE;
            else stop_wait <= 1'b1;
        end
      end
      default: begin
        state <= IDLE;
        tx <= 1'b1;
        tx_busy <= 1'b0;
      end
    endcase
  end
  end

endmodule


module BaudTickGen (
	input wire clk, 
    input wire enable,
	output logic tick  // generate a tick at the specified baud rate * oversampling
);
parameter ClkFrequency = 100000000;
parameter Baud = 115200;
parameter Oversampling = 16;

function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam AccWidth = log2(ClkFrequency/Baud)+8;  // +/- 2% max timing error over a byte
reg [AccWidth:0] Acc = 0;
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));  // this makes sure Inc calculation doesn't overflow
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);
always @(posedge clk) if(enable) Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0]; else Acc <= Inc[AccWidth:0];
assign tick = Acc[AccWidth];
endmodule