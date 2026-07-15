module sva_uart_top #(
    parameter int DATA_BITS = 8
)(
    input logic clk,
    input logic rst_n,
    input logic tx,
    input logic tx_busy,
    input logic rx,
    input logic [DATA_BITS-1:0] rx_data,
    input logic rx_valid,
    input logic frame_error
);

// Check Rx and Tx loopback
always @(posedge clk) begin
    assert (rx === tx)
        else $error("Loopback connection broken");
end

// Check for unknown Rx output
always @(posedge clk) begin
    assert (!$isunknown(rx_data))
        else $error("rx_data contains X");
end

// Check for unknown Tx output
always @(posedge clk) begin
    assert (!$isunknown(tx))
        else $error("tx contains X");
end

// Check if rx_valid and frame_error are mutually exclusive
always @(posedge clk) begin
    assert (!(rx_valid && frame_error))
        else $error("rx_valid and frame_error asserted together");
end

endmodule
