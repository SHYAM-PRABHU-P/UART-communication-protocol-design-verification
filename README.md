# UART Design and Verification using SystemVerilog

## Overview

This repository contains the RTL design and SystemVerilog verification environment for a UART (Universal Asynchronous Receiver Transmitter). The project demonstrates the implementation and verification of UART Transmitter (TX), UART Receiver (RX), and UART Transmitter with Parity using a class-based SystemVerilog testbench.

The verification environment is developed without UVM and follows a reusable architecture consisting of Generator, Driver, Monitor, Scoreboard, and Environment.

---

## Features

### UART TX

* 8-bit data transmission
* Configurable clock frequency and baud rate
* Start bit generation
* Stop bit generation
* Transmission complete (`done_tx`) indication

### UART RX

* Detects start bit
* Receives 8-bit serial data
* Generates received parallel data
* Reception complete (`done_rx`) indication

### UART TX with Parity

* Supports parity bit generation
* Serial transmission of:

  * Start Bit
  * 8 Data Bits
  * Parity Bit
  * Stop Bit

---

## Design Parameters

| Parameter | Description           | Default  |
| --------- | --------------------- | -------- |
| `freq`    | Input Clock Frequency | 1 MHz    |
| `baud`    | UART Baud Rate        | 9600 bps |

---

## Project Structure

```
UART/
│
├── uart_top.sv
├── uart_tx.sv
├── uart_rx.sv
├── uart_tx_parity.sv
│
├── interface.sv
│
├── uart_tb.sv
├── uart_tx_parity_tb.sv
│
└── README.md
```

---

## Verification Architecture

The verification environment consists of the following components:

### Transaction

* Generates randomized UART transactions.
* Stores transmitted and received data.

### Generator

* Randomizes input transactions.
* Sends transactions to the Driver through a mailbox.

### Driver

* Drives randomized data onto the DUT.
* Generates write/read operations.
* Sends expected data to the Scoreboard.

### Monitor

* Observes DUT outputs.
* Captures transmitted and received data.
* Sends actual DUT outputs to the Scoreboard.

### Scoreboard

* Compares expected and actual data.
* Reports pass/fail status.

### Environment

* Connects all verification components.
* Controls simulation flow.
* Performs reset, execution, and simulation completion.

---

## Verification Flow

```
Generator
    │
    ▼
Driver
    │
    ▼
UART DUT
    │
    ▼
Monitor
    │
    ▼
Scoreboard
```

---

## Verification Methodology

* Class-based SystemVerilog verification
* Mailbox-based communication
* Event synchronization
* Randomized stimulus generation
* Self-checking scoreboard
* Functional verification without UVM

---

## UART TX Verification

The UART transmitter is verified for:

* Random 8-bit data transmission
* Start bit generation
* Data bit ordering
* Stop bit generation
* Completion signal generation

The monitor captures the serial output and reconstructs the transmitted byte. The scoreboard compares the reconstructed byte with the original transmitted data.

---

## UART RX Verification

The UART receiver is verified for:

* Detection of start bit
* Correct serial-to-parallel conversion
* Random serial input sequences
* Completion signal generation
* Accurate received data

The scoreboard compares the expected received data with the DUT output.

---

## UART TX with Parity Verification

Additional verification includes:

* Correct parity bit generation
* Transmission of parity after data bits
* Verification of parity using the scoreboard
* Data and parity comparison

---

## Simulation

The design can be simulated using any SystemVerilog simulator such as:

* EDA Playground
* ModelSim
* QuestaSim
* Riviera-PRO
* Xcelium
* VCS

---

## Expected Simulation Result

For each randomized transaction, the scoreboard reports:

```
Successful
----------------------------------------
```

If a mismatch occurs:

```
Unsuccessful
----------------------------------------
```

---

## Concepts Demonstrated

### RTL Design

* UART Transmitter
* UART Receiver
* UART with Parity
* Parameterized modules
* Finite State Machine (FSM)
* Baud-rate clock generation

### Verification

* Object-Oriented Programming (OOP)
* Class-based Testbench
* Randomization
* Mailboxes
* Events
* Virtual Interface
* Self-checking Scoreboard
* Functional Verification

---

## Future Improvements

* Configurable data length (5–9 bits)
* Even/Odd parity selection
* Stop bit configuration (1 or 2 bits)
* Baud rate generator improvements
* UART Loopback verification
* Functional coverage
* Assertions (SVA)
* UVM-based verification environment
* Error injection (Parity, Framing, Overrun)
* FIFO-based UART

---

## Author

**Shyam Prabhu P**

Electronics and Communication Engineering (ECE)

Interested in RTL Design, Design Verification, SystemVerilog, UVM, and Digital VLSI.
