`timescale 1ns/1ps

module tb_baud_generator #(
    // Configuration parameters
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int NUM_TICKS_TO_VERIFY = 100
);

    // Local parameters for reference and timing
    localparam int EXPECTED_DIVISOR = CLOCK_FREQ_HZ / BAUD_RATE;
    localparam real CLOCK_PERIOD_NS = 1.0e9 / CLOCK_FREQ_HZ;
    localparam real HALF_PERIOD_NS  = CLOCK_PERIOD_NS / 2.0;

    // Timeout based on expected runtime
    localparam int TIMEOUT_CYCLES = 10 + ((NUM_TICKS_TO_VERIFY + 2) * EXPECTED_DIVISOR);

    // DUT signals
    logic clk;
    logic rst_n;
    logic baud_tick;

    // Verification statistics
    int tests_run;
    int tests_passed;
    int tests_failed;

    // DUT instantiation
    baud_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(HALF_PERIOD_NS) clk = ~clk;

    // Waveform generation
    initial begin
        $dumpfile("baud_generator_waveform.vcd");
        $dumpvars(0, tb_baud_generator);
    end

    // Watchdog Timer
    initial begin
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "[TIMEOUT] Simulation timed out after %0d cycles. Measurement logic failed.", TIMEOUT_CYCLES);
    end

    // Record test results
    task automatic record_test(input string test_name, input bit passed);
        begin
            tests_run++;
            if (passed) begin
                tests_passed++;
            end else begin
                tests_failed++;
                $error("[FAIL] %s", test_name);
            end
        end
    endtask

    // Verification
    task automatic verify_tick(input int tick_number);
        automatic int cycles = 0;
        begin
            // 1. Pulse Width Check
            // We enter this task exactly at the clock edge where baud_tick == 1.
            // Move forward one clock cycle.
            @(posedge clk);
            cycles++; // Accumulate 1 cycle

            if (baud_tick === 1'b0) begin
                record_test($sformatf("Tick [%0d] Pulse Width is 1 cycle", tick_number), 1'b1);
            end else begin
                record_test($sformatf("Tick [%0d] Pulse Width is wider than 1 cycle", tick_number), 1'b0);
            end

            // 2. Interval Measurement
            // Count cycles while baud_tick remains 0
            while (baud_tick === 1'b0) begin
                @(posedge clk);
                cycles++;
            end

            // The loop breaks exactly when baud_tick == 1 again.
            // Compare the total counted cycles to the divisor.
            if (cycles == EXPECTED_DIVISOR) begin
                record_test($sformatf("Tick [%0d] Interval is exactly %0d cycles", tick_number, EXPECTED_DIVISOR), 1'b1);
            end else begin
                $error("[DEBUG] Tick [%0d]: Expected interval = %0d, Measured = %0d", tick_number, EXPECTED_DIVISOR, cycles);
                record_test($sformatf("Tick [%0d] Interval Check", tick_number), 1'b0);
            end
        end
    endtask

    // Main Test Sequence
    initial begin
        // Initialize stats
        tests_run = 0;
        tests_passed = 0;
        tests_failed = 0;

        // Apply Reset
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;

        // Wait one cycle for synchronous reset release to settle, then verify idle state
        @(posedge clk);
        record_test("Reset Behavior: baud_tick is 0 after reset", (baud_tick === 1'b0));

        // Synchronize to the very first valid baud tick
        // Using a while loop for Icarus Verilog compatibility
        while (baud_tick === 1'b0) begin
            @(posedge clk);
        end

        // Run the verification loop
        for (int i = 1; i <= NUM_TICKS_TO_VERIFY; i++) begin
            verify_tick(i);
        end

        // Print Summary
        $display("\n==================================================");
        $display("               TEST SUMMARY");
        $display("==================================================");
        $display("Module        : baud_generator");
        $display("Clock         : %0d Hz", CLOCK_FREQ_HZ);
        $display("Baud Rate     : %0d", BAUD_RATE);
        $display("Expected Div. : %0d", EXPECTED_DIVISOR);
        $display("--------------------------------------------------");
        $display("Tests Run     : %0d", tests_run);
        $display("Tests Passed  : %0d", tests_passed);
        $display("Tests Failed  : %0d", tests_failed);
        $display("--------------------------------------------------");
        if (tests_failed == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $display("==================================================\n");

        $finish;
    end

endmodule
