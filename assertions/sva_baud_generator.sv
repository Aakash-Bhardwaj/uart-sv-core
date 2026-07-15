module sva_baud_generator #(
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE     = 115_200,
    parameter int DIVISOR       = CLOCK_FREQ_HZ / BAUD_RATE,
    parameter int COUNTER_WIDTH = ($clog2(DIVISOR) < 1) ? 1 : $clog2(DIVISOR)
)(
    input logic clk,
    input logic rst_n,
    input logic baud_tick,
    input logic [COUNTER_WIDTH-1:0] counter
);

// Check for baud tick during reset
always @(posedge clk) begin
    if (!rst_n) begin
        assert (!baud_tick)
            else $error("baud_tick asserted during reset");
    end
end

// Check if baud tick is only one clock wide or not
logic prev_baud_tick;

always @(posedge clk) begin
    prev_baud_tick <= baud_tick;

    if (rst_n && prev_baud_tick) begin
        assert (!baud_tick)
            else $error("baud_tick wider than one clock");
    end
end

// Check for unknown values
always @(posedge clk) begin
    assert (!$isunknown(baud_tick))
        else $error("baud_tick is unknown");
end

// Check if counter exceeds divisor
always @(posedge clk) begin
    if (rst_n) begin
        assert (counter < DIVISOR)
            else $error("Counter exceeded divisor");
    end
end

// Check if counter resets after baud_tick
logic prev_tick;

always @(posedge clk) begin
    prev_tick <= baud_tick;

    if (rst_n && prev_tick) begin
        assert (counter == 0)
            else $error("Counter did not reset after baud_tick");
    end
end

endmodule
