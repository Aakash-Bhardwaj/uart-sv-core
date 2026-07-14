module uart_top #(
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE     = 115_200,
    parameter int DATA_BITS     = 8
) (
    input logic clk,
    input logic rst_n,

    // TX interface
    input logic                     tx_start,
    input logic [DATA_BITS - 1 : 0] tx_data,

    // RX interface
    input logic rx,
    input logic rx_ack,

    // TX output
    output logic tx,
    output logic tx_busy,

    // RX output
    output logic [DATA_BITS - 1 : 0] rx_data,
    output logic                     rx_valid,
    output logic                     frame_error
);

    logic baud_tick;

    // Instantiating baud generator
    baud_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) bg (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // Instantiating UART transmitter
    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Instantiating UART Receiver
    uart_rx #(
        .DATA_BITS(DATA_BITS)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .rx(rx),
        .rx_ack(rx_ack),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .frame_error(frame_error)
    );

    // synthesis translate_off

    // Parameter validation
    initial begin
        bit error_check;
        error_check = 0;
        if (CLOCK_FREQ_HZ <= 0) begin
            $error("Clock frequency cannot be less than or equal to 0");
            error_check = 1;
        end
        if (BAUD_RATE <= 0) begin
            $error("Baud rate cannot be less than or equal to 0");
            error_check = 1;
        end
        if (CLOCK_FREQ_HZ < BAUD_RATE) begin
            $error("Clock frequency cannot be less than baud rate");
            error_check = 1;
        end
        if (DATA_BITS <= 0) begin
            $error("Data bits cannot be less than or equal to 0");
            error_check = 1;
        end
        if (error_check) begin
            $fatal(0);
        end
    end

    // synthesis translate_on

endmodule
