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

### 3.6 Algorithm

1. Validate the configuration parameters.
2. Compute `DIVISOR`.
3. Compute `COUNTER_WIDTH`.
4. Increment `baud_counter` every clock cycle.
5. Compare `baud_counter` against `DIVISOR - 1`.
6. Assert `baud_tick` for one system clock cycle.
7. Reset `baud_counter` after the terminal count.

### 3.7 Design Decisions

- Counter-based clock division.
- Single clock domain.
- Clock-enable (`baud_tick`) instead of generated clocks.
- One-clock-cycle baud tick.
- Counter resets after reaching the terminal count.
- Compile-time parameter validation.
- Deterministic behaviour following reset.
- Counter width derived automatically from the baud divisor.

### 3.8 Corner Cases

- Invalid `CLOCK_FREQ_HZ`
- Invalid `BAUD_RATE`
- `DIVISOR <= 1`
- Counter reset
- First baud tick following reset

### 3.9 Resource Utilization

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

#### Timing Analysis

*To be added after `uart_top` has been implemented.*

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [ ] Static Timing Analysis

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

*To be completed after the datapath diagram has been finalized.*

### 4.6 State Machine

*To be completed after the FSM diagram has been finalized.*

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

#### Timing Analysis

*To be added after `uart_top` has been implemented.*

#### Verification Status

- [x] RTL Simulation
- [x] Self-checking Testbench
- [ ] Assertions
- [x] Synthesis
- [ ] Static Timing Analysis

## 5. UART Receiver

*To be completed.*

## 6. UART Top-Level

*To be completed.*

## 7. Future Improvements

This document will be extended as additional UART features such as parity, FIFOs, configurable stop bits, and flow control are implemented.