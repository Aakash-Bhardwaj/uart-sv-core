# UART SV Core Implementation

## 1. Overview

This document describes the implementation details of each module in the UART SV Core. It complements the project specification and architecture documents by documenting the internal organization, coding style, implementation decisions, and design trade-offs used throughout the project.

## 2. Coding Guidelines

The UART SV Core follows the implementation guidelines below:

- SystemVerilog is used throughout the project.
- Only synthesizable RTL constructs are used.
- Sequential logic is implemented using `always_ff`.
- Combinational logic is implemented using `always_comb`.
- Non-blocking assignments (`<=`) are used for sequential logic.
- Blocking assignments (`=`) are used for combinational logic.
- Enumerated types are used for finite-state machines.
- Three-process FSM architecture is used where applicable.
- Parameters are validated during elaboration whenever possible.
- The design operates entirely within a single clock domain.

## 3. Baud Generator

### 3.1 Module Overview

The baud generator divides the system clock to generate a periodic one-clock-cycle `baud_tick` pulse. The generated pulse acts as a clock-enable signal for the UART transmitter and receiver while maintaining a single synchronous clock domain.

### 3.2 Interface

#### Parameters

| Parameter | Description |
|-----------|-------------|
| `CLOCK_FREQ_HZ` | System clock frequency. |
| `BAUD_RATE` | Desired UART baud rate. |

#### Inputs

| Signal | Description |
|--------|-------------|
| `clk` | System clock |
| `rst_n` | Active-low asynchronous reset |

#### Outputs

| Signal | Description |
|--------|-------------|
| `baud_tick` | One-clock-cycle baud enable pulse |

### 3.3 Derived Parameters

| Parameter | Description |
|-----------|-------------|
| `DIVISOR` | Number of system clock cycles per baud period (`CLOCK_FREQ_HZ / BAUD_RATE`). |
| `COUNTER_WIDTH` | Width of `baud_counter`, computed from `DIVISOR` with a minimum value of one bit. |

### 3.4 Internal Registers

| Register | Width | Purpose |
|----------|------:|---------|
| `baud_counter` | `COUNTER_WIDTH` | Counts system clock cycles until the baud divisor is reached. |

### 3.5 Datapath

*Datapath diagram to be added during final documentation.*

The baud generator datapath consists of:

- Baud counter
- Terminal-count comparator
- Baud tick generation logic

### 3.6 State Machine

*FSM diagram to be added during final documentation.*

The baud generator does not use a finite-state machine. Instead, it repeatedly counts system clock cycles until the configured baud divisor is reached, generates a one-clock-cycle `baud_tick`, resets the counter, and repeats.

### 3.7 Algorithm

1. Validate the configuration parameters.
2. Compute `DIVISOR`.
3. Compute `COUNTER_WIDTH`.
4. Increment `baud_counter` every clock cycle.
5. Compare `baud_counter` against `DIVISOR - 1`.
6. Assert `baud_tick` for one system clock cycle.
7. Reset `baud_counter` after the terminal count.

### 3.8 Design Decisions

- Counter-based clock division.
- Single clock domain.
- Clock-enable (`baud_tick`) instead of generated clocks.
- One-clock-cycle baud tick.
- Counter resets after reaching the terminal count.
- Compile-time parameter validation.
- Deterministic behaviour following reset.
- Counter width derived automatically from the baud divisor.

### 3.9 Corner Cases

- Invalid `CLOCK_FREQ_HZ`
- Invalid `BAUD_RATE`
- `DIVISOR <= 1`
- Counter reset
- First baud tick following reset

### 3.10 Resource Utilization

#### Synthesis Results

- Tool: Yosys
- Script: `scripts/synth_baud_generator.ys`

| Metric | Value |
|--------|------:|
| Number of Ports | 3 |
| Total Cell Count | 51 |
| Sequential Cells | 9 |
| Combinational Cells | 42 |
| Memory Blocks | 0 |

#### Cell Breakdown

| Cell Type | Count |
|-----------|------:|
| AND | 11 |
| DFF_PN0 | 9 |
| MUX | 9 |
| NOT | 6 |
| OR | 8 |
| XOR | 8 |

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [x] Static Timing Analysis

## 4. UART Transmitter

### 4.1 Module Overview

The UART transmitter converts parallel input data into a serial UART frame consisting of one start bit, `DATA_BITS` data bits transmitted LSB first, and one stop bit.

### 4.2 Interface

#### Parameters

| Parameter | Description |
|-----------|-------------|
| `DATA_BITS` | Number of transmitted data bits. |

#### Inputs

| Signal | Description |
|--------|-------------|
| `clk` | System clock |
| `rst_n` | Active-low asynchronous reset |
| `baud_tick` | Baud-rate enable pulse |
| `tx_start` | Starts transmission |
| `tx_data` | Parallel transmit data |

#### Outputs

| Signal | Description |
|--------|-------------|
| `tx` | Serial transmit output |
| `tx_busy` | Indicates active transmission |

### 4.3 Internal Registers

| Register | Width | Purpose |
|----------|------:|---------|
| `state` | `state_t` | Current FSM state |
| `shift_reg` | `DATA_BITS` | Stores data currently being transmitted |
| `bit_count` | Depends on implementation | Counts transmitted data bits |

### 4.4 Combinational Signals

| Signal | Purpose |
|--------|---------|
| `next_state` | Next FSM state |
| `next_shift_reg` | Next shift register value |
| `next_bit_count` | Next bit counter value |
| `next_tx` | Next transmit output |
| `next_tx_busy` | Next busy flag |

### 4.5 Datapath

*Datapath diagram to be added during final documentation.*

The transmitter datapath consists of:

- Shift register
- Bit counter
- Output registers

### 4.6 State Machine

*FSM diagram to be added during final documentation.*

The transmitter uses a four-state finite-state machine.

| State | Function |
|--------|----------|
| `IDLE` | Waits for a transmission request |
| `START_BIT` | Transmits the start bit |
| `DATA_TX` | Transmits the data bits |
| `STOP_BIT` | Transmits the stop bit and returns to `IDLE` |

### 4.7 Algorithm

1. Wait for `tx_start` while in the `IDLE` state.
2. Latch `tx_data` into the shift register.
3. Transmit the start bit.
4. Transmit each data bit on successive `baud_tick` pulses.
5. Shift the register after transmitting each bit.
6. Count transmitted bits.
7. Transmit the stop bit.
8. Return to the `IDLE` state.

### 4.8 Design Decisions

- Three-process FSM implementation.
- Enumerated FSM states.
- Single clock domain.
- `baud_tick` used as a clock-enable.
- Output current bit before shifting.
- LSB-first transmission.
- Ignore `tx_start` while busy.
- Support back-to-back transmissions.

### 4.9 Corner Cases

- Reset during transmission.
- Repeated `tx_start` assertions.
- Minimum supported `DATA_BITS`.
- Maximum supported `DATA_BITS`.
- Back-to-back frame transmission.

### 4.10 Resource Utilization

#### Synthesis Results

- Tool: Yosys
- Script: `scripts/synth_uart_tx.ys`

| Metric | Value |
|--------|------:|
| Number of Ports | 7 |
| Total Cell Count | 69 |
| Sequential Cells | 14 |
| Combinational Cells | 55 |
| Memory Blocks | 0 |

#### Cell Breakdown

| Cell Type | Count |
|-----------|------:|
| ANDNOT | 23 |
| AND | 3 |
| DFFE_PN0P | 13 |
| DFFE_PN1P | 1 |
| MUX | 9 |
| NAND | 2 |
| NOR | 4 |
| NOT | 4 |
| ORNOT | 2 |
| OR | 6 |
| XNOR | 1 |
| XOR | 1 |

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [x] Static Timing Analysis

## 5. UART Receiver

### 5.1 Module Overview

The UART receiver converts serial UART frames into parallel data. Incoming asynchronous serial data is synchronized before being sampled using the shared `baud_tick` clock-enable signal. Valid frames are presented to user logic through a handshake interface consisting of `rx_valid` and `rx_ack`.

### 5.2 Interface

#### Parameters

| Parameter | Description |
|-----------|-------------|
| `DATA_BITS` | Number of received data bits. |

#### Inputs

| Signal | Description |
|--------|-------------|
| `clk` | System clock |
| `rst_n` | Active-low asynchronous reset |
| `baud_tick` | Baud-rate enable pulse |
| `rx` | Serial receive input |
| `rx_ack` | Acknowledges received data |

#### Outputs

| Signal | Description |
|--------|-------------|
| `rx_data` | Parallel received data |
| `rx_valid` | Indicates valid received data |
| `frame_error` | Indicates an invalid stop bit |

### 5.3 Internal Registers

| Register | Width | Purpose |
|----------|------:|---------|
| `state` | `state_t` | Current FSM state |
| `sync_ff1` | 1 | First synchronizer stage |
| `sync_ff2` | 1 | Second synchronizer stage |
| `rx_sync` | 1 | Synchronized receive input |
| `prev_rx_sync` | 1 | Previous synchronized input for edge detection |
| `shift_reg` | `DATA_BITS` | Stores received serial data |
| `rx_bit_counter` | Depends on implementation | Counts received data bits |
| `rx_data_reg` | `DATA_BITS` | Stores completed received byte |
| `rx_valid_reg` | 1 | Registered valid flag |
| `frame_error_reg` | 1 | Registered framing error flag |

### 5.4 Combinational Signals

| Signal | Purpose |
|--------|---------|
| `next_state` | Next FSM state |
| `next_shift_reg` | Next shift register value |
| `next_rx_bit_counter` | Next bit counter value |
| `next_rx_data_reg` | Next received data value |
| `next_rx_valid_reg` | Next valid flag |
| `next_frame_error_reg` | Next framing error flag |

### 5.5 Datapath

*Datapath diagram to be added during final documentation.*

The receiver datapath consists of:

- Two-stage input synchronizer
- Falling-edge detector
- Shift register
- Bit counter
- Output registers

### 5.6 State Machine

*FSM diagram to be added during final documentation.*

The receiver uses a four-state finite-state machine.

| State | Function |
|-------|----------|
| `IDLE` | Waits for the start of a new frame |
| `DATA_RX` | Receives and reconstructs serial data |
| `STOP_BIT` | Validates the stop bit |
| `HANDSHAKE` | Holds received data or error status until acknowledged |

### 5.7 Algorithm

1. Synchronize the asynchronous receive input.
2. Detect the falling edge indicating the start bit.
3. Receive `DATA_BITS` serial bits.
4. Shift previously received bits toward the least-significant bit.
5. Insert the newly received bit into the most-significant bit.
6. Count received bits.
7. Sample the stop bit.
8. Assert `rx_valid` for a valid frame.
9. Assert `frame_error` for an invalid stop bit.
10. Hold the status until `rx_ack` is asserted.
11. Return to the `IDLE` state.

### 5.8 Design Decisions

- Three-process FSM implementation.
- Enumerated FSM states.
- Single clock domain.
- `baud_tick` used as a clock-enable.
- Two-stage synchronizer for asynchronous serial input.
- Falling-edge start-bit detection.
- Shift-left data reconstruction with MSB insertion.
- Handshake interface using `rx_valid` and `rx_ack`.
- Registered error reporting.
- Compile-time parameter validation.

### 5.9 Corner Cases

- Reset during reception.
- False start-bit detection.
- Invalid stop bit.
- Back-to-back frame reception.
- Minimum supported `DATA_BITS`.
- Maximum supported `DATA_BITS`.

### 5.10 Resource Utilization

#### Synthesis Results

- Tool: Yosys
- Script: `scripts/synth_uart_rx.ys`

| Metric | Value |
|--------|------:|
| Number of Ports | 8 |
| Total Cell Count | 196 |
| Sequential Cells | 27 |
| Combinational Cells | 168 |
| Memory Blocks | 0 |

#### Cell Breakdown

| Cell Type | Count |
|-----------|------:|
| AND | 49 |
| DFFE_PNOP | 24 |
| DFF_PN0 | 3 |
| MUX | 64 |
| NOT | 15 |
| OR | 39 |
| XOR | 2 |

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [x] Static Timing Analysis

## 6. UART Top-Level

### 6.1 Module Overview

The `uart_top` module integrates the baud generator, UART transmitter, and UART receiver into a reusable UART IP core. It performs hierarchical module integration without introducing additional datapath or control logic.

### 6.2 Interface

#### Parameters

| Parameter | Description |
|-----------|-------------|
| `CLOCK_FREQ_HZ` | System clock frequency. |
| `BAUD_RATE` | UART baud rate. |
| `DATA_BITS` | Number of transmitted and received data bits. |

#### Inputs

| Signal | Description |
|--------|-------------|
| `clk` | System clock |
| `rst_n` | Active-low asynchronous reset |
| `tx_start` | Starts transmission |
| `tx_data` | Parallel transmit data |
| `rx` | Serial receive input |
| `rx_ack` | Acknowledges received data |

#### Outputs

| Signal | Description |
|--------|-------------|
| `tx` | Serial transmit output |
| `tx_busy` | Indicates active transmission |
| `rx_data` | Parallel received data |
| `rx_valid` | Indicates valid received data |
| `frame_error` | Indicates an invalid stop bit |

### 6.3 Internal Signals

| Signal | Purpose |
|--------|---------|
| `baud_tick` | Shared baud-rate enable pulse generated by the baud generator |

### 6.4 Datapath

*Datapath diagram to be added during final documentation.*

The top-level datapath consists of:

- Baud generator
- UART transmitter
- UART receiver
- Shared `baud_tick` interconnect

### 6.5 Module Hierarchy

*Hierarchy diagram to be added during final documentation.*

The top-level module instantiates:

| Module | Function |
|--------|----------|
| `baud_generator` | Generates the shared baud-rate enable pulse |
| `uart_tx` | Serializes and transmits parallel data |
| `uart_rx` | Receives serial data and reconstructs parallel data |

### 6.6 Algorithm

1. Validate configuration parameters.
2. Instantiate the baud generator.
3. Generate the shared `baud_tick` signal.
4. Distribute `baud_tick` to the transmitter and receiver.
5. Forward transmit requests to the UART transmitter.
6. Forward received data and status from the UART receiver.
7. Operate transmitter and receiver concurrently.

### 6.7 Design Decisions

- Hierarchical module integration.
- Single clock domain.
- Shared `baud_tick` clock-enable.
- No additional datapath logic.
- No additional finite-state machine.
- Parameter propagation to submodules.
- Modular and reusable architecture.
- Compile-time parameter validation.

### 6.8 Corner Cases

- Invalid parameter values.
- Reset during transmission.
- Reset during reception.
- Simultaneous transmit and receive operation.
- Back-to-back frame transmission.

### 6.9 Resource Utilization

#### Synthesis Results

- Tool: Yosys
- Script: `scripts/synth_uart_top.ys`

| Metric | Value |
|--------|------:|
| Number of Ports | 11 |
| Total Cell Count | 425 |
| Sequential Cells | 50 |
| Combinational Cells | 375 |
| Memory Blocks | 0 |

#### Cell Breakdown

| Cell Type | Count |
|-----------|------:|
| AND | 110 |
| DFFE_PN0P | 37 |
| DFFE_PN1P | 1 |
| DFF_PN0 | 12 |
| MUX | 124 |
| NOT | 35 |
| OR | 94 |
| XOR | 12 |

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [x] Static Timing Analysis

## 7. Technology Mapped Synthesis

- Tool: Yosys
- Technology: Sky130 HDLL
- Script: `scripts/synth_sky130.ys`
- Total Cell Count: 172
- Total Area: 2204.6144 µm²

| Module         | Cell Count | Area (µm²) |
| -------------- | ---------: | ---------: |
| Baud Generator |         32 |   402.8864 |
| UART TX        |         59 |   669.3920 |
| UART RX        |         81 |  1132.3360 |
| UART Top       |        172 |  2204.6144 |

## 8. Static Timing Analysis

- Tool: OpenSTA
- Library: Sky130 HDLL TT
- Script: `scripts/timing_uart.tcl`
- Voltage: 1.8 V
- Temperature: 25°C
- Clock period: 20 ns (50 MHz)

Results:

- Setup timing: PASS
- Worst setup slack: 14.565 ns
- WNS: 0.00 ns
- TNS: 0.00 ns

No setup timing violations were observed under the applied timing constraints.

## 9. Future Improvements

This document will be extended as additional UART features such as parity, FIFOs, configurable stop bits, and flow control are implemented.