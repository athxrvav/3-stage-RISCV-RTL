# 3-Stage Pipelined RISC-V RV32I Core

A custom 32-bit RISC-V processor core designed from scratch in Verilog. This project implements a high-throughput 3-stage pipeline architecture (Fetch, Decode, Execute) featuring a robust hardware hazard resolution unit. 

This core serves as an optimized foundation for embedded computing, demonstrating practical applications of instruction-level parallelism, data forwarding, and pipeline stall logic.

## Architecture Overview

To optimize for a smaller footprint and rapid instruction turnaround, this core utilizes a streamlined 3-stage pipeline, compressing the traditional memory and writeback phases directly into the execute stage. 

1. **Fetch (IF):** Program Counter logic, Branch Target multiplexing, and Instruction Memory access.
2. **Decode (ID):** Instruction decoding, Register File read, Immediate generation, and Control Unit.
3. **Execute (EX):** ALU computation, Data Memory Read/Write, Branch evaluations, and Register Writeback.

### Key Hardware Features

* **Data Forwarding Unit:** Dynamically resolves Read-After-Write (RAW) data hazards. It utilizes a 3-way multiplexer system at the ALU inputs to bypass the register file, forwarding calculated data directly from the Execute stage back to consecutive instructions requiring that data.
* **Load-Use Hazard Detection:** A hardware stall unit that monitors for 'lw' (load word) dependencies, freezing the PC and IF/ID registers while inserting a NOP bubble to safely accommodate memory access latency.
* **Synchronous Branch Flushing:** Resolves control hazards by aggressively flushing the IF/ID and ID/EX pipeline registers when a branch decision is resolved, preventing the execution of improperly fetched instructions.

## Supported Instruction Set (RV32I Subset)

The core currently implements a highly functional subset of the Base Integer (RV32I) Instruction Set Architecture, utilizing a custom ALU and ALU Decoder.

* **Arithmetic:** add, sub, addi
* **Logical:** and, or, xor (including immediate variants handled via ALU decoder)
* **Shifts:** sll, srl, sra (Logical Left, Logical Right, Arithmetic Right)
* **Comparisons:** slt, sltu (Set Less Than Signed/Unsigned)
* **Memory Interface:** lw (Load Word), sw (Store Word)
* **Control Flow:** beq (Branch if Equal)

## Getting Started

### Prerequisites

* Simulator: Xilinx Vivado, Icarus Verilog, or Verilator.
* Waveform Viewer: GTKWave (if using Icarus).

### Running Simulation

1. Clone the repository to your local machine.
2. Add the Verilog files located in the `src/` and `tb/` directories to your simulation project.
3. Ensure the `program.hex` file is correctly referenced in `inst_mem.v` using the `$readmemh` system task. Use a relative path to ensure cross-platform compatibility.
4. Run the Behavioral Simulation. Observe the pipeline registers and the Forwarding/Stall signals in the Hazard Unit to verify proper instruction flow.

## Future Work & Roadmap

* Complete RV32I ISA: Implement remaining Jumps (jal, jalr), upper immediates (lui, auipc), and sub-word memory accesses.
* RTL-to-GDSII Physical Design: Push the design through the OpenLane/OpenROAD ASIC flow targeting the SkyWater 130nm process node.
* Automated Verification Environment: Implement a comprehensive SystemVerilog testbench for automated architectural compliance testing.
