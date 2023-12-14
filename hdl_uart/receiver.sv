
module receiver (
  input wire clk_in,
  input wire rst_in,
  input wire rx,
  input wire sample_tick_in,
  output logic data_valid,
  output logic [7:0] received_data
);

  // Define states
  typedef enum {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT,
    CLEANUP
  } state_r;

  // Define state register
  state_r state;

  // Define internal signals
  logic [3:0] bit_counter;
  logic [7:0] data_holder;
  logic [3:0] sample_counter; //Overflows at 16
  logic prev_rx;

  // State machine
  always_ff @(posedge clk_in) begin
    prev_rx <= rx;
    if (rst_in) begin
      state <= IDLE;
      bit_counter <= 0;
      data_holder <= 0;
      data_valid <= 0;
      received_data <= 0;
    end else begin
        // Increment sample_tick (16 times per baud tick)
      case (state)
        IDLE:begin
          data_valid <= 0;
          data_holder <= 0; // Clear data holder
          if (!rx && prev_rx) begin
            state <= START_BIT;
            bit_counter <= 0;
            sample_counter <= 0;
            received_data <= 0;
          end
        end

        
        START_BIT:begin // Recieve start bit
        //Reset sample_counter at midpoint of signal
          if (sample_tick_in) begin
            if (sample_counter == 9) begin
              if (!rx) begin // Valid start bit
                bit_counter <= 0;
                state <= DATA_BITS;
                sample_counter <= 0;
              end else begin // Invalid start bit
                bit_counter <= 0;
                state <= IDLE;
              end
            end
        //Increment sample_counter
            else begin
              sample_counter <= sample_counter + 1;
            end
          end
        end

        DATA_BITS:begin
            if (sample_tick_in) begin
                sample_counter <= sample_counter + 1;
            end
        //Sample bit at midpoint of signal
          if (sample_counter == 15) begin
        
        // Not all bits recieved
          if (bit_counter < 8) begin
            sample_counter <= 0;
            data_holder[bit_counter] <= rx;
            bit_counter <= bit_counter + 1;

        // All bits recieved
          end else begin
            state <= STOP_BIT;
            bit_counter <= 0;
          end
        end
        end

        // Recieve 1 stop bit
        STOP_BIT: begin
        if(sample_tick_in) begin
          if (sample_counter == 15) begin
            if (rx) begin //Data valid on stop bit recieved else invalid
              state <= IDLE;
              data_valid <= 1;
              received_data <= data_holder;
            end else begin
              state <= IDLE;
            end
          end
          sample_counter <= sample_counter + 1;
        end
        end
      endcase
    end
  end

endmodule
