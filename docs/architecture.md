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

## 7. UART Receiver

## 8. Top-Level Integration

## 9. Design Decisions

## 10. Future Architecture Extensions