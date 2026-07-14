# UART SV Core Architecture

## 1. Design Overview

The UART SV Core follows a modular architecture in which baud generator, transmitter, and receiver are implemented as independent modules. Communication between modules is synchronized using the system clock, while `baud_tick` is used as a clock-enable signal rather than generating a derived clock.

## 2. Design Philosophy

The UART SV Core is designed according to the following principles:

- Modular design
- Parameterization
- Single clock domain
- Reusability
- Synthesizable RTL
- Clear separation between datapath and control
- Documentation-driven development

## 3. Module Hierarchy

```
                 uart_top
                    │
     ┌──────────────┼──────────────┐
     │              │              │
     ▼              ▼              ▼
baud_generator   uart_tx       uart_rx
```

| Module | Description |
|---------|-------------|
| `baud_generator` | Generates baud-rate tick pulses from the system clock. |
| `uart_tx` | Serializes and transmits parallel data. |
| `uart_rx` | Receives serial data and reconstructs parallel data. |
| `uart_top` | Integrates the transmitter, receiver, and baud generator. |

## 4. Data Flow

### Transmitter:

```
tx_data
   │
   ▼
Shift Register
   │
   ▼
 TX Pin
```
Parallel input data is latched into an internal shift register and serialized for transmission under the control of the transmitter FSM.

### Receiver:

```
RX Pin
   │
   ▼
Synchronizer
   │
   ▼
Shift Register
   │
   ▼
rx_data
```
Incoming serial data is synchronized, sampled at the configured baud rate, and reconstructed into parallel data before being presented to the user logic.

## 5. Baud Generator

The baud generator produces a one-clock-cycle `baud_tick` pulse that is used as a clock-enable signal throughout the UART. No derived clock is generated.

The baud generator consists of:

- A parameterized counter
- Terminal count detection
- Combinational tick generation

The baud divisor is calculated as:

`DIVISOR = CLOCK_FREQ_HZ / BAUD_RATE`

The counter increments every system clock cycle and resets upon reaching DIVISOR−1. A combinational comparator asserts `baud_tick` for one clock cycle whenever the terminal count is reached.

This architecture maintains a single clock domain and avoids internally generated clocks.

## 6. UART Transmitter

The UART transmitter converts parallel input data into a serial UART frame consisting of one start bit, DATA_BITS data bits (LSB first), and one stop bit.

The transmitter is implemented as a finite-state machine with four states:

- IDLE
- START_BIT
- DATA_TX
- STOP_BIT

Transmission is synchronized using `baud_tick`, which acts as a clock-enable signal. No derived clocks are generated.

During transmission:

- Input data is latched into an internal shift register.
- The current least-significant bit is transmitted.
- The shift register shifts right after each transmitted bit.
- A bit counter tracks the transmitted bits.
- `tx_busy` remains asserted until the stop bit has completed.

The transmitter supports back-to-back transmissions by accepting a new `tx_start` request immediately after the stop bit.

## 7. UART Receiver

The UART receiver converts incoming serial UART frames into parallel data consisting of one start bit, `DATA_BITS` data bits (LSB first), and one stop bit.

Incoming serial data is synchronized using a two-stage flip-flop synchronizer before being processed by the receiver state machine.

The receiver is implemented as a finite-state machine with four states:

- IDLE
- DATA_RX
- STOP_BIT
- HANDSHAKE

Reception is synchronized using `baud_tick`, which acts as a clock-enable signal. No derived clocks are generated.

During reception:

- Incoming serial data is synchronized before sampling.
- A falling edge on the synchronized input initiates frame reception.
- Data bits are sampled on successive `baud_tick` pulses.
- Previously received bits shift toward the least-significant bit while the newly received bit is inserted into the most-significant bit of the shift register.
- A bit counter tracks the number of received data bits.
- The stop bit is validated after all data bits have been received.
- `rx_valid` is asserted following successful reception of a complete frame.
- `frame_error` is asserted if the received stop bit is invalid.
- Received data and status are held until acknowledged through `rx_ack`.

This architecture maintains a single clock domain and avoids internally generated clocks.

## 8. Top-Level Integration

The `uart_top` module integrates the baud generator, UART transmitter, and UART receiver into a reusable UART IP core.

The baud generator produces a shared `baud_tick` signal that is distributed to both the transmitter and receiver as a clock-enable signal. All modules operate using the same system clock, maintaining a single synchronous clock domain throughout the design.

The top-level module contains no additional datapath or control logic. Its primary responsibilities are:

- Instantiating each submodule.
- Passing configuration parameters to the submodules.
- Routing the shared `baud_tick` signal.
- Connecting the external transmit and receive interfaces.

The transmitter and receiver operate independently, allowing simultaneous transmission and reception (full-duplex operation).

The top-level module exposes a clean interface consisting of:

- System clock and reset.
- Transmit control and data interface.
- Receive data and handshake interface.
- Serial transmit and receive signals.

This modular architecture allows each submodule to be verified independently while enabling straightforward system-level integration and reuse.

## 9. Future Architecture Extensions