module baud_generator #(
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int BAUD_RATE = 115_200
) (
    input logic clk,
    input logic rst_n,
    output logic baud_tick
);
    
    // To calculate the width of baud counter
    localparam int DIVISOR = CLOCK_FREQ_HZ / BAUD_RATE;
    // Calculating width of baud counter
    localparam int COUNTER_WIDTH = ($clog2(DIVISOR) < 1) ? 1 : $clog2(DIVISOR); 
    logic [COUNTER_WIDTH - 1 : 0] baud_counter;

    // Clock cycle counter for baud generation
    always_ff @(posedge clk or negedge rst_n) begin : baud_counter_ff
        if (!rst_n)
            baud_counter <= 0;
        else if (baud_counter == DIVISOR - 'd1)
            baud_counter <= 0;
        else
            baud_counter <= baud_counter + 1;        
    end

    // Output logic
    assign baud_tick = (baud_counter == DIVISOR - 'd1);

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
        if (error_check) begin
            $fatal(0);
        end
    end

    // synthesis translate_on

endmodule
