`timescale 1ns/1ps

module tb_uart_rx #(
    // Configuration parameter
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int DATA_BITS = 8
);

    // Local parameters for reference and timing
    localparam int BAUD_DIVISOR = 10;
    localparam int TIMEOUT_CYCLES = 15000;
    localparam int RESET_CYCLES = 5;
    // Align the falling edge so that, after the synchronizer latency,
    // the receiver detects the start bit on the intended baud_tick.
    localparam int SYNC_OFFSET = BAUD_DIVISOR - 4;
    localparam real CLOCK_PERIOD_NS = 1.0e9 / CLOCK_FREQ_HZ;
    localparam real HALF_PERIOD_NS  = CLOCK_PERIOD_NS / 2.0;

    // DUT signals
    logic clk;
    logic rst_n;
    logic baud_tick;
    logic rx;
    logic rx_ack;
    logic [DATA_BITS - 1 : 0] rx_data;
    logic rx_valid;
    logic frame_error;

    // Verification statistics
    int tests_run;
    int tests_passed;
    int tests_failed;

    bit pass;
    logic [DATA_BITS-1:0] payloads [3];

    // Instantiate DUT
    uart_rx #(
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .rx(rx),
        .rx_ack(rx_ack),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .frame_error(frame_error)
    );

    // Assertions
    sva_uart_rx #(
        .DATA_BITS(DATA_BITS)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .rx_sync(dut.rx_sync),
        .rx_ack(rx_ack),
        .shift_reg(dut.shift_reg),
        .rx_data(rx_data),
        .rx_bit_counter(dut.rx_bit_counter),
        .rx_valid(rx_valid),
        .frame_error(frame_error),
        .state(dut.state)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(HALF_PERIOD_NS) clk = ~clk;

    // Timeout watchdog
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1,"[TIMEOUT] Simulation hung! Watchdog triggered after %0d cycles.", TIMEOUT_CYCLES);
    end

    // Synthetic Baud Generator
    initial begin
        baud_tick = 1'b0;
        forever begin
            repeat(BAUD_DIVISOR - 1) @(posedge clk);
            baud_tick <= 1'b1; // Assert on rising edge
            @(posedge clk);
            baud_tick <= 1'b0; // De-assert on rising edge
        end
    end

    // Waveform generation
    initial begin
        $dumpfile("uart_rx_waveform.vcd");
        $dumpvars(0, tb_uart_rx);
    end

    // Helper Tasks

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

    // Abstracting bus driver for the specific strict-edge DUT
    task automatic send_uart_frame(input logic [DATA_BITS-1:0] data, input logic good_stop = 1'b1);
        begin
            // Sync to the exact moment baud_tick evaluates
            while (!baud_tick) @(posedge clk);

            // Wait to align the rx drop so that exactly 3 clock cycles later (sync delay),
            // the falling edge perfectly aligns with the next baud_tick evaluation.
            repeat (SYNC_OFFSET) @(posedge clk);
            rx = 1'b0; // Start bit

            // Wait for the baud tick where start bit is sampled
            while (!baud_tick) @(posedge clk);

            // Drive data bits (DUT samples on baud_tick, shift reg handles it directly)
            for (int i = 0; i < DATA_BITS; i++) begin
                // FIX: Step past the clock cycle where baud_tick is currently 1
                // to prevent the zero-time fall-through of the while loop.
                @(posedge clk);
                rx = data[i];
                while (!baud_tick) @(posedge clk);
            end

            // Drive stop bit
            @(posedge clk); // FIX: Step past current baud_tick
            rx = good_stop;
            while (!baud_tick) @(posedge clk);

            // Leave line high (Idle state)
            @(posedge clk);
            rx = 1'b1;
        end
    endtask

    // Helper tasks end

    // Main Test Sequence
    initial begin
        // Initialize lines
        tests_run = 0;
        tests_passed = 0;
        tests_failed = 0;
        rx = 1'b1;
        rx_ack = 1'b0;
        rst_n = 1'b1;

        $display("========================================");
        $display("   Starting UART RX Verification Suite  ");
        $display("========================================");

        // Reset Behavior
        rst_n = 1'b0;
        repeat(RESET_CYCLES) @(posedge clk);
        record_test("Test 1 - Reset Behavior", (rx_valid == 0 && frame_error == 0 && rx_data == 0));
        rst_n = 1'b1;
        repeat(5) @(posedge clk);

        // Single Frame Reception
        send_uart_frame(8'hA5);
        wait (rx_valid);
        record_test("Test 2 - Single Frame Reception", (rx_data === 8'hA5 && frame_error === 1'b0));
        @(posedge clk); rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;

        // Multiple Payloads
        begin
            pass = 1;
            payloads[0] = 8'h11;
            payloads[1] = 8'h22;
            payloads[2] = 8'h33;
            for (int i=0; i<3; i++) begin
                send_uart_frame(payloads[i]);
                wait (rx_valid);
                if (rx_data !== payloads[i]) pass = 0;
                @(posedge clk); rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;
            end
            record_test("Test 3 - Multiple Payloads", pass);
        end

        // rx_valid Handshake
        send_uart_frame(8'h5A);
        wait (rx_valid);
        // Delay acknowledgment to verify stability
        repeat(BAUD_DIVISOR * 3) @(posedge clk);
        if (rx_valid === 1'b1) begin
            rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;
            record_test("Test 4 - rx_valid Handshake", 1);
        end else begin
            record_test("Test 4 - rx_valid Handshake", 0);
        end

        // Data Stability
        send_uart_frame(8'hCC);
        wait (rx_valid);
        rx = 1'b0; // Simulate noise on RX line during handshake phase
        repeat(BAUD_DIVISOR) @(posedge clk);
        rx = 1'b1;
        repeat(BAUD_DIVISOR) @(posedge clk);
        record_test("Test 5 - Data Stability", (rx_data === 8'hCC && rx_valid === 1'b1));
        rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;

        // Frame Error Detection
        send_uart_frame(8'h55, 1'b0); // Send bad stop bit (0 instead of 1)
        wait (rx_valid || frame_error);
        record_test("Test 6 - Frame Error Detection", (frame_error === 1'b1 && rx_valid === 1'b0));
        rx_ack = 1'b1; wait (!frame_error); @(posedge clk); rx_ack = 1'b0;

        // False Start Detection
        while (!baud_tick) @(posedge clk);
        repeat(2) @(posedge clk);
        rx = 1'b0; // Pull low out of sync
        repeat(SYNC_OFFSET - 2) @(posedge clk);
        rx = 1'b1; // Pull high before the exact sampling window evaluates
        repeat(BAUD_DIVISOR * DATA_BITS) @(posedge clk); // Wait to next baud_tick check
        record_test("Test 7 - False Start Detection", (rx_valid === 1'b0 && frame_error === 1'b0));

        // Mid-Frame Reset
        while (!baud_tick) @(posedge clk);
        repeat (SYNC_OFFSET) @(posedge clk);
        rx = 1'b0; // Send Start bit
        while (!baud_tick) @(posedge clk);
        @(posedge clk); // FIX: Step past current baud_tick
        rx = 1'b1; while (!baud_tick) @(posedge clk); // Send data bit 0
        @(posedge clk); // FIX: Step past current baud_tick
        rx = 1'b0; while (!baud_tick) @(posedge clk); // Send data bit 1
        rst_n = 1'b0; // Trigger reset midway
        repeat(3) @(posedge clk);
        record_test("Test 8 - Mid-Frame Reset", (rx_valid === 1'b0 && frame_error === 1'b0));
        rst_n = 1'b1;
        rx = 1'b1;
        repeat(BAUD_DIVISOR) @(posedge clk);

        // Back-to-Back Frames
        send_uart_frame(8'hAA);
        wait (rx_valid);
        rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;
        send_uart_frame(8'hBB); // Send immediately on back of clearing previous valid flag
        wait (rx_valid);
        record_test("Test 9 - Back-to-Back Frames", (rx_data === 8'hBB));
        rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;

        // All Ones Payload
        send_uart_frame(8'hFF); // Verifying upper extremes
        wait(rx_valid);
        record_test("Test 10 - All Ones Payload", (rx_data === 8'hFF));
        rx_ack = 1'b1; wait (!rx_valid); @(posedge clk); rx_ack = 1'b0;

        // Summary
        $display("\n==================================================");
        $display("               RX TEST SUMMARY");
        $display("===================================================");
        $display("Tests Run    : %0d", tests_run);
        $display("Tests Passed : %0d", tests_passed);
        $display("Tests Failed : %0d", tests_failed);
        if (tests_failed == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $display("===================================================");

        $finish;
    end

endmodule
