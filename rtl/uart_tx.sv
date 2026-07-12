module uart_tx #(
    parameter int DATA_BITS = 8
) (
    input logic clk,
    input logic rst_n,
    input logic baud_tick,
    input logic tx_start,
    input logic [DATA_BITS - 1 : 0] tx_data,
    output logic tx,
    output logic tx_busy
);

    typedef enum logic [1:0] {  IDLE, 
                                START_BIT, 
                                DATA_TX, 
                                STOP_BIT} state_t;

    state_t state, next_state;
    logic [DATA_BITS - 1 : 0] shift_reg, next_reg;
    logic next_tx, reg_tx;
    localparam int COUNTER_WIDTH = $clog2(DATA_BITS) == 0 ? 1 : $clog2(DATA_BITS);
    logic [COUNTER_WIDTH - 1: 0] tx_bit_counter, next_tx_bit_counter;

    // State transition logic
    always @(*) begin
        next_state = state;
        next_tx = reg_tx;
        next_reg = shift_reg;
        next_tx_bit_counter = tx_bit_counter;
        case (state)
            IDLE: begin
                if (tx_start) begin
                   next_state = START_BIT;
                   next_tx = 1'b0;
                   next_reg = tx_data;
                end
                else begin
                    next_state = IDLE;
                    next_tx = 1'b1;
                end
            end
            START_BIT: begin 
                if (baud_tick) begin
                   next_state = DATA_TX;
                   next_tx_bit_counter = 'd0;
                   next_tx = shift_reg[0];
                   next_reg = shift_reg >> 1; 
                end
            end
            DATA_TX: begin
               if (baud_tick) begin
                    next_tx = shift_reg[0];
                    next_reg = shift_reg >> 1;
                    if (tx_bit_counter == DATA_BITS - 'd1) begin
                        next_state = STOP_BIT;
                        next_tx = 1'b1;
                    end
                    else begin
                        next_state = DATA_TX;
                        next_tx_bit_counter = tx_bit_counter + 1;
                    end
               end 
            end
            STOP_BIT: begin
                next_tx = 1'b1;
                if (baud_tick) begin
                    if (tx_start) begin
                        next_state = START_BIT;
                        next_tx = 1'b0;
                        next_reg = tx_data;
                    end
                    else begin
                        next_state = IDLE;
                        next_tx = 1'b1;
                    end
                end
            end 
            default: begin
               next_state = IDLE;
               next_tx = 1'b1;
               next_reg = 0;
               next_tx_bit_counter = 0;
            end
        endcase
    end

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            reg_tx <= 1'b1;
            tx_bit_counter <= 'd0;
            shift_reg <= 'd0;
        end
        else if (baud_tick || (state == IDLE)) begin
            state <= next_state;
            tx_bit_counter <= next_tx_bit_counter;
            reg_tx <= next_tx;
            shift_reg <= next_reg; 
        end
    end

    // Output logic
    assign tx = reg_tx;
    assign tx_busy = (state != IDLE);

    // synthesis translate_off
    
    // Parameter validation
    initial begin
        bit error_check;
        error_check = 0;
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
