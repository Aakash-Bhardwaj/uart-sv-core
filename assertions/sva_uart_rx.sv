module sva_uart_rx #(
    parameter int DATA_BITS = 8,
    parameter int COUNTER_WIDTH = ($clog2(DATA_BITS) == 0) ? 1 : $clog2(DATA_BITS)
)(
    input logic clk,
    input logic rst_n,
    input logic baud_tick,
    input logic rx_sync,
    input logic rx_ack,
    input logic [DATA_BITS-1:0] shift_reg,
    input logic [DATA_BITS-1:0] rx_data,
    input logic [COUNTER_WIDTH-1:0] rx_bit_counter,
    input logic rx_valid,
    input logic frame_error,
    input logic [2:0] state
);

// Check counter overflow
always @(posedge clk) begin
    if (rst_n) begin
        assert (rx_bit_counter < DATA_BITS)
            else $error("RX bit counter overflow");
    end
end

// Check for unknown states
always @(posedge clk) begin
    assert (!$isunknown(state))
        else $error("RX FSM entered unknown state");
end

// Check for unknown value in shift register
always @(posedge clk) begin
    assert (!$isunknown(shift_reg))
        else $error("RX shift register contains X");
end

// Check for unknown output data
always @(posedge clk) begin
    assert (!$isunknown(rx_data))
        else $error("RX data contains X");
end

// Check if rx_valid and frame_error are high together
always @(posedge clk) begin
    assert (!(rx_valid && frame_error))
        else $error("rx_valid and frame_error asserted together");
end

// Check rx_valid
always @(posedge clk) begin
    if (rst_n && rx_valid) begin
        assert (state == 3'd3)
            else $error("rx_valid asserted outside HANDSHAKE");
    end
end

// Check frame_error
always @(posedge clk) begin
    if (rst_n && frame_error) begin
        assert (state == 3'd3)
            else $error("frame_error asserted outside HANDSHAKE");
    end
end

// Check if output clears after reset
always @(posedge clk) begin
    if (!rst_n) begin
        assert (!rx_valid)
            else $error("rx_valid asserted during reset");

        assert (!frame_error)
            else $error("frame_error asserted during reset");
    end
end

endmodule
