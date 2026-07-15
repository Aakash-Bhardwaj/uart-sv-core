`timescale 1ns/1ps

module tb_uart_tx #(
    // Configuration parameter
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int DATA_BITS = 8
);

    // Local parameters for reference and timing
    localparam int BAUD_DIVISOR = 10;
    localparam int TIMEOUT_CYCLES = 15000;
    localparam int RESET_CYCLES = 5;
    localparam real CLOCK_PERIOD_NS = 1.0e9 / CLOCK_FREQ_HZ;
    localparam real HALF_PERIOD_NS  = CLOCK_PERIOD_NS / 2.0;

    // DUT signals
    logic clk;
    logic rst_n;
    logic baud_tick;
    logic tx_start;
    logic [DATA_BITS - 1 : 0] tx_data;
    logic tx;
    logic tx_busy;

    // Verification statistics
    int tests_run;
    int tests_passed;
    int tests_failed;
    bit idle_failed;

    // Instantiate DUT
    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Assertions
    sva_uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .shift_reg(dut.shift_reg),
        .tx_bit_counter(dut.tx_bit_counter),
        .state(dut.state)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(HALF_PERIOD_NS) clk = ~clk;

    // Timeout watchdog
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "[TIMEOUT] Simulation hung! Watchdog triggered after %0d cycles.",TIMEOUT_CYCLES);
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
        $dumpfile("uart_tx_waveform.vcd");
        $dumpvars(0, tb_uart_tx);
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

    // Synchronize to the next baud tick
    task automatic wait_baud_tick();
        begin
            // Wait until the current tick finishes
            while (baud_tick) @(posedge clk);

            // Wait for the next tick
            while (!baud_tick) @(posedge clk);

            // Move into the stable region of the new bit
            repeat(BAUD_DIVISOR / 2) @(posedge clk);
        end
    endtask

    // Abstracting bus driver
    task automatic send_byte(input logic [DATA_BITS-1:0] data);
        begin
            wait_baud_tick();
            @(negedge clk);
            tx_data = data;
            tx_start = 1'b1;
            @(negedge clk);
            tx_start = 1'b0;
        end
    endtask

    // Helper tasks end

    // Verification
    task automatic verify_uart_frame(input logic [DATA_BITS - 1 : 0] expected_data);
        automatic logic [DATA_BITS - 1 : 0] received_data = 0;
        begin
            // 1. Wait for Start Bit
            while (tx === 1'b1) begin
                @(negedge clk);
            end
            record_test($sformatf("Start Bit detected for payload %h", expected_data), 1'b1);

            // 2. Sync to the baud tick that ends the start bit
            wait_baud_tick();

            // 3. Sample Data Bits
            for (int i = 0; i < DATA_BITS; i++) begin
                received_data[i] = tx; // Sample immediately in the stable zone
                wait_baud_tick();      // Wait for the tick to cross into the next bit
            end

            if (received_data === expected_data)
                record_test($sformatf("Payload Match: Expected %h, Got %h",
                                        expected_data, received_data), 1'b1);
            else
                record_test($sformatf("Payload Mismatch: Expected %h, Got %h",
                                        expected_data, received_data), 1'b0);

            // 4. Verify Stop Bit
            // Because the loop just ended with wait_baud_tick(), we are 1 cycle into the Stop Bit.
            if (tx === 1'b1)
                record_test("Stop Bit correctly driven HIGH", 1'b1);
            else
                record_test("Stop Bit Failed", 1'b0);

            // 5. Wait for the Stop Bit period to conclude so RTL returns to IDLE cleanly
            wait_baud_tick();
        end
    endtask

    // Main Test Sequence
    initial begin
        // Initialize signals
        idle_failed = 0;
        rst_n = 1'b0;
        tx_start = 1'b0;
        tx_data = '0;

        // Apply Reset
        repeat(RESET_CYCLES) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;

        $display("\n--- TEST 1: Single Transmission (0xA5) ---");
        send_byte(8'hA5);
        verify_uart_frame(8'hA5);

        repeat(20) @(posedge clk);

        $display("\n--- TEST 2: Single Transmission (0x3C) ---");
        send_byte(8'h3C);
        verify_uart_frame(8'h3C);

        repeat(20) @(posedge clk);

        $display("\n--- TEST 3: Mid-Transmission Reset ---");
        send_byte(8'hFF);

        while (tx === 1'b1) @(negedge clk); // Wait for Start bit
        repeat(3) wait_baud_tick();         // Let 3 bits transmit

        @(negedge clk) rst_n = 1'b0;        // Abrupt reset
        @(posedge clk);

        if (tx === 1'b1 && tx_busy === 1'b0)
            record_test("Hardware safely aborted transmission and returned to IDLE", 1'b1);
        else
            record_test("Hardware failed to recover from mid-frame reset", 1'b0);

        repeat(5) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;

        $display("\n--- TEST 4: Data Change During Active Transmission ---");
        send_byte(8'h55);
        @(negedge clk) tx_data = 8'hAA; // Sabotage input bus immediately after start
        verify_uart_frame(8'h55);       // Should still safely output latched 0x55

        $display("\n--- TEST 5: IDLE State Verification ---");
        idle_failed = 0;
        if (tx === 1'b1 && tx_busy === 1'b0) begin
            for (int i = 0; i < 100; i++) begin
                @(negedge clk);
                if (tx !== 1'b1 || tx_busy !== 1'b0) idle_failed = 1;
            end

            if (!idle_failed)
                record_test("IDLE state continuously holds TX high and tx_busy low", 1'b1);
            else
                record_test("IDLE state drifted or glitched", 1'b0);
        end else begin
            record_test("Failed to enter IDLE state before test began", 1'b0);
        end

        $display("\n--- TEST 6: tx_busy Flag & Ignored Requests ---");
        // Fork splits the simulation into parallel threads
        fork
            begin // THREAD 1: Standard Receiver
                send_byte(8'hC3);
                verify_uart_frame(8'hC3);
            end

            begin // THREAD 2: The Attacker
                repeat(4) wait_baud_tick(); // Wait until FSM is deep in DATA_TX state

                if (tx_busy === 1'b1)
                    record_test("tx_busy is High during active transmission", 1'b1);
                else
                    record_test("tx_busy failed to assert", 1'b0);

                send_byte(8'h99); // Try to force a new transmission while busy
            end
        join

        repeat(2) wait_baud_tick();
        if (tx === 1'b1 && tx_busy === 1'b0)
            record_test("Transmitter ignored rogue tx_start and returned to IDLE", 1'b1);
        else
            record_test("Transmitter erroneously started transmitting the rogue payload", 1'b0);

        // Summary
        $display("\n==================================================");
        $display("               TX TEST SUMMARY");
        $display("==================================================");
        $display("Tests Run     : %0d", tests_run);
        $display("Tests Passed  : %0d", tests_passed);
        $display("Tests Failed  : %0d", tests_failed);
        if (tests_failed == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $display("==================================================\n");

        $finish;
    end

endmodule
