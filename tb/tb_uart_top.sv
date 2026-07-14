`timescale 1ns/1ps

module tb_uart_top #(
    // Configuration parameter
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE     = 115_200,
    parameter int DATA_BITS     = 8
);

    // Local parameters for reference and timing
    localparam int BAUD_DIVISOR = CLOCK_FREQ_HZ / BAUD_RATE;
    localparam int TIMEOUT_CYCLES = 50000;
    localparam int RESET_CYCLES = 5;
    localparam real CLOCK_PERIOD_NS = 1.0e9 / CLOCK_FREQ_HZ;
    localparam real HALF_PERIOD_NS  = CLOCK_PERIOD_NS / 2.0;

    // DUT signals
    logic                     clk;
    logic                     rst_n;
    logic                     tx_start;
    logic [DATA_BITS - 1 : 0] tx_data;
    logic                     rx;
    logic                     rx_ack;
    logic                     tx;
    logic                     tx_busy;
    logic [DATA_BITS - 1 : 0] rx_data;
    logic                     rx_valid;
    logic                     frame_error;

    // Verification statistics
    int tests_run;
    int tests_passed;
    int tests_failed;

    // Initializing test variables
    logic [DATA_BITS-1:0] payloads [6];
    logic [DATA_BITS-1:0] captured;

    // Instantiate DUT
    uart_top #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .rx(rx),
        .rx_ack(rx_ack),
        .tx(tx),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .frame_error(frame_error)
    );

    // Loopback connection
    assign rx = tx;

    // Clock generation
    initial clk = 1'b0;
    always #(HALF_PERIOD_NS) clk = ~clk;

    // Timeout watchdog
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1,"[TIMEOUT] Simulation hung! Watchdog triggered after %0d cycles.", TIMEOUT_CYCLES);
    end

    // Waveform generation
    initial begin
        $dumpfile("uart_top_waveform.vcd");
        $dumpvars(0, tb_uart_top);
    end

    // Initializing verification statistics
    initial begin
        tests_run    = 0;
        tests_passed = 0;
        tests_failed = 0;
    end

    // Record test results
    task automatic record_test(input string test_name, input bit passed);
        begin
            tests_run++;
            if (passed) begin
                tests_passed++;
                $display("[PASS] %s", test_name);
            end else begin
                tests_failed++;
                $error("[FAIL] %s", test_name);
            end
        end
    endtask

    // Helper tasks

    // Apply reset
    task automatic apply_reset;
        begin
            rst_n    = 1'b0;
            tx_start = 1'b0;
            tx_data  = 'd0;
            rx_ack   = 1'b0;

            repeat (RESET_CYCLES) @(posedge clk);

            rst_n = 1'b1;

            @(posedge clk);
        end
    endtask

    // Data transmission
    task automatic transmit_frame (input logic [DATA_BITS - 1 : 0] data);
        begin
            // Load payload
            tx_data = data;

            // Pulse tx_start
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;

            // Wait for transmission to begin
            while (!tx_busy)
                @(posedge clk);

            // Wait for transmission to end
            while (tx_busy)
                @(posedge clk);

            // Wait for reception to end
            while (!rx_valid && !frame_error)
                @(posedge clk);
        end
    endtask

    // Acknowledge data
    task automatic acknowledge_data;
        begin
           rx_ack = 1'b1;
           @(posedge clk);
           rx_ack = 1'b0;
        end
    endtask

    // Print Summary
    task automatic print_summary;
        begin

            $display("\n==================================================");
            $display("             UART TOP TEST SUMMARY");
            $display("==================================================");

            $display("Tests Run    : %0d", tests_run);
            $display("Tests Passed : %0d", tests_passed);
            $display("Tests Failed : %0d", tests_failed);

            if (tests_failed == 0)
                $display("OVERALL RESULT : PASS");
            else
                $display("OVERALL RESULT : FAIL");

            $display("==================================================");

        end
    endtask

    // Helper tasks end

    // Main test sequence
    initial begin
        // Reset behavior test
        $display("\n--- TEST 1: Reset Behaviour ---");
        apply_reset();
        record_test("TX idle after reset", tx == 1'b1);
        record_test("TX busy cleared", tx_busy == 1'b0);
        record_test("RX valid cleared", rx_valid == 1'b0);
        record_test("Frame error cleared", frame_error == 1'b0);
        record_test("RX data cleared", rx_data == 'd0);

        // Loopback test
        $display("\n--- TEST 2: Single Loopback ---");
        transmit_frame(8'hA5);
        record_test("Received correct data", rx_data == 8'hA5);
        record_test("RX valid asserted", rx_valid);
        record_test("No frame error", !frame_error);
        acknowledge_data();
        @(posedge clk);
        record_test("RX valid cleared after acknowledge", !rx_valid);

        // Multiple payload test
        payloads[0] = 8'h00;
        payloads[1] = 8'h55;
        payloads[2] = 8'hA5;
        payloads[3] = 8'hFF;
        payloads[4] = 8'h3C;
        payloads[5] = 8'hC3;

        $display("\n--- TEST 3: Multiple Payloads ---");
        foreach (payloads[i]) begin
            transmit_frame(payloads[i]);
            record_test($sformatf("Payload %0h received", payloads[i]), rx_data == payloads[i]);
            acknowledge_data();
            @(posedge clk);
        end

        // Handshake test
        $display("\n--- TEST 4: Handshake ---");
        transmit_frame(8'h96);
        captured = rx_data;
        repeat (20) @(posedge clk);
        record_test("RX valid held until acknowledge", rx_valid);
        record_test("RX data stable", rx_data == captured);
        acknowledge_data();
        @(posedge clk);
        record_test("RX valid cleared", !rx_valid);

        // Back to back frames
        $display("\n--- TEST 5: Back-to-Back Frames ---");

        transmit_frame(8'h12);
        record_test("Received 12", rx_data == 8'h12);
        acknowledge_data();
        @(posedge clk);

        transmit_frame(8'h34);
        record_test("Received 34", rx_data == 8'h34);
        acknowledge_data();
        @(posedge clk);

        transmit_frame(8'h56);
        record_test("Received 56", rx_data == 8'h56);
        acknowledge_data();
        @(posedge clk);

        // Mid transmission reset
        $display("\n--- TEST 6: Mid-Transmission Reset ---");

        tx_data = 8'hFF;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;

        while (!tx_busy)
            @(posedge clk);

        rst_n = 1'b0;
        repeat (RESET_CYCLES)
            @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        record_test("TX busy cleared after reset", !tx_busy);
        record_test("RX valid cleared after reset", !rx_valid);
        record_test("Frame error cleared after reset", !frame_error);
        record_test("TX returned to idle", tx == 1'b1);

        // Sumamry
        print_summary();
        $finish;

    end

endmodule
