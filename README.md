# UART SV Core

A parameterized Universal Asynchronous Receiver-Transmitter (UART) IP core written in SystemVerilog.

This project follows a structured RTL engineering workflow, progressing from specification and architecture through implementation, verification, synthesis, and static timing analysis. The goal is to develop a reusable UART IP core while emphasizing good design practices, documentation, and reproducibility.

This project emphasizes correctness, modularity, parameterization, and reproducibility. Each design decision is documented, verified, synthesized, and analyzed before integration.

---

## Objectives

- Design a reusable UART IP core
- Follow modern SystemVerilog coding practices
- Develop comprehensive self-checking testbenches
- Verify functionality using simulation and assertions
- Perform synthesis using Yosys
- Perform static timing analysis using OpenSTA
- Maintain clear documentation throughout development

---

## Planned Features

### Version 1

- [x] Parameterized clock frequency
- [x] Parameterized baud rate
- [x] Parameterized data width
- [x] UART transmitter
- [x] UART receiver
- [ ] Full-duplex operation
- [x] 1 stop bit
- [ ] No parity
- [x] Busy flag
- [x] Data valid flag

### Future Enhancements

- [ ] Configurable parity
- [ ] Configurable stop bits
- [ ] Configurable oversampling
- [ ] TX/RX FIFOs
- [ ] Interrupt support
- [ ] Formal verification

---

## Repository Structure

```
rtl/            Synthesizable SystemVerilog RTL
tb/             Testbenches
docs/           Design documentation
constraints/    Timing constraints
scripts/        Utility scripts
```

---

## Toolchain

| Tool | Purpose |
|------|----------|
| SystemVerilog | RTL Design |
| Icarus Verilog | Simulation |
| GTKWave | Waveform Viewing |
| Yosys | Logic Synthesis |
| OpenSTA | Static Timing Analysis |
| Git | Version Control |

---

## Development Workflow

```
Specification
      ↓
Architecture
      ↓
RTL Design
      ↓
Verification
      ↓
Simulation
      ↓
Synthesis
      ↓
Timing Analysis
      ↓
Documentation
```

---

## Project Status

- [x] Repository initialized
- [x] Design specification
- [x] Architecture
- [x] Baud generator RTL
- [x] Baud generator verification
- [x] Baud generator synthesis
- [x] UART transmitter RTL
- [x] UART transmitter verification
- [x] UART transmitter synthesis
- [x] UART receiver RTL
- [x] UART receiver verification
- [x] UART receiver synthesis
- [ ] Top-level integration
- [ ] Top-level verification
- [ ] Top-level synthesis
- [ ] Static timing analysis

---

## License

This project is licensed under the MIT License.