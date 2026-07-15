# UART SV Core Verification Plan

## 1. Verification Objectives

The objective of verification is to ensure that the UART SV Core satisfies all functional requirements defined in the project specification.

Verification shall confirm correct functionality through simulation, self-checking testbenches, assertions, and synthesis.

## 2. Verification Methodology

Verification shall follow a layered approach consisting of:

- Directed testing
- Self-checking testbenches
- Immediate SystemVerilog assertions
- Waveform analysis
- Synthesis using Yosys
- Static timing analysis using OpenSTA

## 3. Verification Environment

| Tool | Use |
|------|-----|
| Icarus Verilog | Simulation |
| GTKWave | Waveform viewing |
| yosys | Synthesis |
| OpenSTA | Timing analysis |

## 4. Module Verification

### 4.1 Baud Generator

- Verify correct baud tick generation.
- Verify divisor calculation.
- Verify reset behavior.
- Verify tick periodicity.

### 4.2 UART Transmitter

- Verify idle state.
- Verify start bit.
- Verify data transmission.
- Verify stop bit.
- Verify busy signal.
- Verify parameterized data width.

### 4.3 UART Receiver

- Verify start detection.
- Verify data reconstruction.
- Verify stop bit.
- Verify rx_valid.
- Verify reset behavior.

### 4.4 Top-Level UART

- Verify end-to-end communication.
- Verify multiple frames.
- Verify back-to-back transmission.

## 5. Functional Test Cases

The following test cases shall be implemented as self-checking testbenches.

### 5.1 Baud Generator

Verified using a self-checking SystemVerilog testbench.

Verified properties:

- Reset behaviour
- First baud tick timing
- Tick periodicity
- One-clock pulse width
- 100 consecutive baud intervals
- Parameter validation
- Self-checking

### 5.2 UART Transmitter

Verified using a self-checking SystemVerilog testbench.

Verified properties:

- Reset behaviour
- Idle state
- Start bit generation
- LSB-first data transmission
- Stop bit generation
- tx_busy assertion/deassertion
- Data latching during transmission
- Mid-transmission reset
- Ignoring tx_start while busy
- Parameterized DATA_BITS support

### 5.3 UART Receiver

Verified using a self-checking SystemVerilog testbench.

Verified properties:

- Reset behaviour
- Single-frame reception
- Multiple payload reception
- rx_valid assertion
- rx_valid handshake
- Data stability before acknowledgement
- Frame error detection
- False start detection
- Mid-frame reset
- Back-to-back frame reception

### 5.4 Top-Level UART

Verified using a self-checking SystemVerilog integration testbench.

Verified properties:

- Reset behaviour
- End-to-end loopback communication
- Single-frame transmission
- Multiple payload transmission
- Back-to-back frame transmission
- `rx_valid` handshake
- Data stability before acknowledgement
- Simultaneous transmitter and receiver operation
- Mid-transmission reset
- Parameterized integration

## 6. Assertions

Immediate SystemVerilog assertions were implemented to verify key design invariants during simulation.

Verified properties:

- Reset behaviour
- Counter bounds
- FSM consistency
- Output validity
- Detection of unknown (`X/Z`) values
- Mutual exclusion of status signals
- Loopback integration invariants

All assertions passed during simulation.

## 7. Coverage Goals

- Verify all FSM states.
- Verify all FSM transitions.
- Verify all supported frame types.
- Verify parameter configurations.
- Verify reset conditions.

## 8. Success Criteria

Verification is considered complete when:

- All planned tests pass.
- All assertions pass.
- No simulation errors remain.
- Synthesis completes successfully.
- Static timing analysis reports no timing violations.

## 9. Static Timing Analysis Results

Static timing analysis was performed using OpenSTA with the Sky130 HDLL
standard-cell timing library.

Results:

- Worst Negative Slack (WNS): 0.00 ns
- Total Negative Slack (TNS): 0.00 ns
- Worst setup slack: 14.565 ns
- No setup timing violations observed under the applied timing constraints.

## 10. Future Verification Enhancements

- UVM
- Cocotb