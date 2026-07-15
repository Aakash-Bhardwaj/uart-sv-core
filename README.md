# UART SV Core

A parameterized Universal Asynchronous Receiver-Transmitter (UART) IP core written in SystemVerilog.

This project follows a structured RTL engineering workflow, progressing from specification and architecture through implementation, verification, synthesis, and static timing analysis. The goal is to develop a reusable UART IP core while emphasizing good design practices, documentation, and reproducibility.

This project emphasizes correctness, modularity, parameterization, and reproducibility. Each design decision is documented, verified, synthesized, and analyzed before integration.

---

## Objectives

- Design a reusable UART IP core
- Follow modern SystemVerilog coding practices
- Develop comprehensive self-checking testbenches
- Verify functionality using self-checking testbenches and immediate SystemVerilog assertions
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
- [x] Full-duplex operation
- [x] 1 stop bit
- [x] No parity
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
rtl/             Synthesizable SystemVerilog RTL
tb/              Self-checking testbenches
docs/            Project documentation
docs/images/     Architecture, FSM, datapath and waveform figures
constraints/     OpenSTA timing constraints
scripts/         Synthesis and timing scripts
reports/         Synthesis and timing reports
assertions/      Contains immediate SystemsVerilog assertions
```

---

## Documentation

The project documentation is organized into the following documents:

| Document | Description |
|----------|-------------|
| [Specification](docs/specification.md) | Functional requirements, timing requirements, assumptions, and future enhancements. |
| [Architecture](docs/architecture.md) | System architecture, module hierarchy, design philosophy, and integration. |
| [Implementation](docs/implementation.md) | Detailed implementation of each module, algorithms, synthesis, timing analysis, and design decisions. |
| [Verification Plan](docs/verification.md) | Verification methodology, test plan, synthesis validation, and timing verification. |

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
- [x] Baud generator assertions
- [x] UART transmitter RTL
- [x] UART transmitter verification
- [x] UART transmitter synthesis
- [x] UART transmitter assertions
- [x] UART receiver RTL
- [x] UART receiver verification
- [x] UART receiver synthesis
- [x] UART receiver assertions
- [x] Top-level integration
- [x] Top-level verification
- [x] Top-level synthesis
- [x] Top-level assertions
- [x] Static timing analysis

---

## Results

- All self-checking testbenches passed
- Generic synthesis completed successfully using Yosys
- Technology-mapped synthesis completed using Sky130 HDLL
- Static timing analysis passed using OpenSTA
- No setup timing violations observed

---

## License

This project is licensed under the MIT License.