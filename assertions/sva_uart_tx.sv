module sva_uart_tx #(
    parameter int DATA_BITS = 8,
    parameter int WIDTH     = $clog2(DATA_BITS)==0 ? 0 : $clog2(DATA_BITS)
)(
    input logic clk,
    input logic rst_n,
    input logic baud_tick,
    input logic tx_start,
    input logic tx,
    input logic tx_busy,
    input logic [DATA_BITS - 1 : 0] shift_reg,
    input logic [WIDTH - 1 : 0] tx_bit_counter,
    input logic [1:0] state
);

// Tx idle during reset
always @(posedge clk) begin
    if (!rst_n) begin
        assert (tx == 1'b1)
            else $error("TX not idle during reset");
    end
end

// tx_busy high only in non-IDLE states
always @(posedge clk) begin
    if (rst_n) begin
        assert (tx_busy == (state != 2'd0))
            else $error("tx_busy inconsistent with FSM state");
    end
end

// Check for unknown values of tx
always @(posedge clk) begin
    assert (!$isunknown(tx))
        else $error("tx contains X/Z");
end

// Check if counter exceeds range
always @(posedge clk) begin
    if (rst_n) begin
        assert (tx_bit_counter < DATA_BITS)
            else $error("Bit counter overflow");
    end
end

// Check stop bit
always @(posedge clk) begin
    if (rst_n && state == 2'd3) begin
        assert (tx == 1'b1)
            else $error("Stop bit not high");
    end
end

// Check IDLE line
always @(posedge clk) begin
    if (rst_n && state == 2'd0) begin
        assert (tx == 1'b1)
            else $error("TX line not high in IDLE");
    end
end

// Check for unknown values in shift register
always @(posedge clk) begin
    assert (!$isunknown(shift_reg))
        else $error("Shift register contains X");
end

endmodule
