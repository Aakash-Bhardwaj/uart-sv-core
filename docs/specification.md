# UART SV Core Specification

## 1. Introduction

The UART SV Core is a reusable parameterized UART IP written in SystemVerilog. The design targets synthesizable RTL and follows a modular architecture consisting of a baud generator, transmitter, receiver, and top-level integration module.

## 2. Scope

This specification defines the functional and non-functional requirements for Version 1.0 of the UART SV Core.

The initial implementation focuses on a standard UART supporting full-duplex communication with configurable clock frequency, baud rate, and data width. Advanced UART features such as parity, FIFOs, flow control, and interrupt generation are outside the scope of this version.

## 3. Functional Requirements

The UART SV Core shall:

- Support independent transmitter and receiver operation (full-duplex).
- Support parameterized system clock frequency.
- Support parameterized baud rate.
- Support parameterized data width.
- Transmit one start bit.
- Transmit one stop bit.
- Transmit data LSB first.
- Generate a `tx_busy` status signal while transmission is in progress.
- Generate an `rx_valid` signal after a valid frame has been received.
- Transmitter shall accept a transmission request only while idle.
- Operate entirely within a single clock domain.
- Keep the transmission line high while idle.

## 4. Parameters

| Parameter | Description |
|-----------|-------------|
| `CLOCK_FREQ_HZ` | System clock frequency in Hertz. |
| `BAUD_RATE` | UART baud rate. |
| `DATA_BITS` | Number of data bits per frame. |

## 5. Frame Format

Version 1.0 shall implement the following UART frame:

```
Idle (1)

↓

Start Bit (0)

↓

DATA_BITS data bits (LSB first)

↓

Stop Bit (1)
```

The default configuration corresponds to the standard **8N1** UART format:

- 8 data bits
- No parity
- 1 stop bit

## 6. Timing Requirements

- The baud generator shall generate a one-clock-cycle `baud_tick`.
- One `baud_tick` shall be generated every baud period.
- All sequential logic shall operate on the rising edge of the system clock.
- The design shall use clock-enable pulses (`baud_tick`) rather than internally generated clocks.
- Outputs shall change only on clock edges.

## 7. Reset Behaviour

The UART SV Core shall use an active-low asynchronous reset with synchronous release.

Following reset:

- TX output shall return to the idle state.
- RX logic shall return to its idle state.
- Internal counters shall be cleared.
- Internal state machines shall return to their initial states.
- Status outputs shall return to their default values.

## 8. Assumptions

The following assumptions apply to Version 1.0:

- A stable system clock is available.
- Transmitter and receiver share the same clock domain.
- Baud-rate mismatch between communicating devices remains within UART tolerance.
- External serial inputs are synchronized before use within the receiver.
- The transmitter shall ignore new transmission requests while `tx_busy` is asserted.

## 9. Future Enhancements

Future versions of the UART SV Core may include:

- Configurable parity
- Configurable stop bits
- Configurable oversampling ratio
- Fractional baud-rate generator
- TX/RX FIFOs
- Interrupt support
- Hardware flow control
- Error detection and reporting
- Formal verification