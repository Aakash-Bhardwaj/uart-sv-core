module uart_rx #(
    parameter int DATA_BITS = 8
) (
    input logic clk,
    input logic rst_n,
    input logic baud_tick,
    input logic rx,
    input logic rx_ack,
    output logic [DATA_BITS - 1 : 0] rx_data,
    output logic rx_valid,
    output logic frame_error
);

    typedef enum logic [2:0] {  IDLE,
                                DATA_RX,
                                STOP_BIT,
                                HANDSHAKE} state_t;

    state_t state, next_state;
    logic [DATA_BITS - 1 : 0] shift_reg, next_shift_reg;
    logic [DATA_BITS - 1 : 0] rx_data_reg, next_rx_data_reg;
    localparam int COUNTER_WIDTH = ($clog2(DATA_BITS) == 0) ? 1 : $clog2(DATA_BITS);
    logic [COUNTER_WIDTH - 1: 0] rx_bit_counter, next_rx_bit_counter;
    logic sync_ff1, sync_ff2;
    logic rx_sync;
    logic rx_valid_reg, next_rx_valid_reg;
    logic frame_error_reg, next_frame_error_reg;

    // Synchronize
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 0;
            sync_ff2 <= 0;
            rx_sync <= 0;
        end
        else begin
            sync_ff1 <= rx;
            sync_ff2 <= sync_ff1;
            rx_sync <= sync_ff2;
        end
    end

    // State transition logic
    always_comb begin : state_transition_logic
        next_state = state;
        next_shift_reg = shift_reg;
        next_rx_bit_counter = rx_bit_counter;
        next_rx_data_reg = rx_data_reg;
        next_rx_valid_reg = rx_valid_reg;
        next_frame_error_reg = frame_error_reg;
        case (state)
            IDLE: begin
                next_rx_bit_counter = 'd0;
                next_shift_reg = 'd0;
                if (baud_tick) begin
                    if (!rx_sync)
                        next_state =  DATA_RX;
                    else
                        next_state =  IDLE;
                end
            end
            DATA_RX: begin
                if (baud_tick) begin
                    next_shift_reg = shift_reg >> 1;
                    next_shift_reg[DATA_BITS - 1] = rx_sync;
                    if (rx_bit_counter == DATA_BITS - 1) begin
                        next_state = STOP_BIT;
                    end
                    else begin
                        next_state = DATA_RX;
                        next_rx_bit_counter = rx_bit_counter + 1'b1;
                    end
                end
            end
            STOP_BIT: begin
                if (baud_tick) begin
                    if (rx_sync == 1) begin
                        next_rx_valid_reg = 1'b1;
                        next_rx_data_reg = shift_reg;
                        next_state = HANDSHAKE;
                    end
                    else begin
                        next_frame_error_reg = 1'b1;
                        next_state = HANDSHAKE;
                    end
                end
            end
            HANDSHAKE: begin
                if (rx_ack) begin
                    next_state = IDLE;
                    next_rx_valid_reg = 1'b0;
                    next_frame_error_reg = 1'b0;
                end
            end
            default: begin
                next_state = IDLE;
                next_shift_reg = 'd0;
                next_rx_bit_counter = 'd0;
                next_rx_data_reg = 'd0;
                next_rx_valid_reg = 1'b0;
                next_frame_error_reg = 1'b0;
            end
        endcase
    end

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 'd0;
            rx_bit_counter <= 'd0;
            rx_valid_reg <= 1'b0;
            frame_error_reg <= 1'b0;
            rx_data_reg <= 'd0;
        end
        else if (baud_tick || state == IDLE || state == HANDSHAKE) begin
            state <= next_state;
            shift_reg <= next_shift_reg;
            rx_bit_counter <= next_rx_bit_counter;
            rx_data_reg <= next_rx_data_reg;
            rx_valid_reg <= next_rx_valid_reg;
            frame_error_reg <= next_frame_error_reg;
        end
    end

    // Output logic
    assign rx_data = rx_data_reg;
    assign rx_valid = rx_valid_reg;
    assign frame_error = frame_error_reg;

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
