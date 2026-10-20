# Dual Port RAM (DPRAM) with ROM-Based Self-Test System

---

## Project Overview
This project implements a **basic on-chip memory subsystem** consisting of a **Dual Port RAM (DPRAM)** and a **Read-Only Memory (ROM)** along with supporting logic such as **address counters** and an **adder**.

The design demonstrates **independent read and write operations** using two address ports operating on **separate clock domains**, a concept commonly used in FIFO and buffer memory architectures.

---

## 🧠 Design Description
A **Dual Port RAM** provides two independent address ports.  
In this implementation:

- **Port A** is used for **write operations**
- **Port B** is used for **read operations**
- Read and write ports run on **different clock frequencies**

The **ROM** is pre-initialized with control data that:
- Provides an **offset value** to the adder
- Controls the **Write Enable (WEA)** signal of the DPRAM

This configuration creates a **self-testing loop** that verifies the correctness of memory access and data integrity.

---

## ⚙️ Functional Flow
1. ROM outputs offset and write enable signals
2. Up counter generates write address
3. Down counter generates read address
4. Adder combines input data with ROM offset
5. Modified data is written into DPRAM
6. Data is read back via second port to validate operation

---

## 🧩 Block Diagram
<p align="center">
  <img src="Images/Screenshot 2025-12-29 152308.png" alt=" Pin diagram" width="800">
</p>

> **Note:** the diagram above is the original design idea (PLL with 75/25 MHz clocks, a 9-bit data path,
> and ROM bit 8 driving the write enable). The RTL in `Design codes/` is a simplified version: one clock
> in `top.v`, 8-bit data, a 64-entry RAM, write enable = counter enable, and the ROM data is written
> straight into the RAM (the adder output only goes to `sum_out`). `dpram.v` itself has two independent
> clocks and is verified with different read/write clocks.

---

## 🗂️ Project File Structure
```
├── top.v # Top-level module
├── dpram.v # Dual Port RAM module
├── rom.v # ROM module
├── rom_data.mem # ROM initialization file
├── up_counter.v # Write address counter
├── down_counter.v # Read address counter
├── adder.v # Adder logic
├── tb_top_memory_system.v # Testbench
```

---

## Simulation Results

<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 09.46.05.jpeg" alt=" Pin diagram" width="800">
</p>

---

##  Synthesis
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 10.45.28.jpeg" alt=" Pin diagram" width="800">
</p>

---

## 📊 Resource Utilization
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.16.26.jpeg" alt=" Pin diagram" width="800">
</p>
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.16.49.jpeg" alt=" Pin diagram" width="800">
</p>
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.18.22.jpeg" alt=" Pin diagram" width="800">
</p>
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.18.46.jpeg" alt=" Pin diagram" width="800">
</p>
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.19.10.jpeg" alt=" Pin diagram" width="800">
</p>
<p align="center">
  <img src="Images/WhatsApp Image 2025-11-20 at 11.21.18.jpeg" alt=" Pin diagram" width="800">
</p>

---

## ✅ Verification
The design is verified with a UVM 1.2 environment (Vivado xsim, run inside WSL, waveforms in GTKWave) at two levels.
Full details are in [`docs/spec.md`](docs/spec.md), [`docs/test_plan.md`](docs/test_plan.md) and [`docs/bug_log.md`](docs/bug_log.md).

| Level | DUT | Environment | Tests |
|---|---|---|---|
| Block | `dpram.v` | write agent + read agent, scoreboard with a reference memory, functional coverage, SVA assertions | 8 tests, 12 regression runs (incl. different read/write clocks) |
| System | `top.v` | control agent (`rst`, `en`), cycle-accurate reference model of the whole datapath | 3 tests, run with the real ROM and a scrambled ROM |

**Results**
- Block regression: 12 of 12 runs pass; `full_test` reaches 100% functional coverage.
- Mutation testing: 8 of 8 injected `dpram.v` bugs and 8 of 8 injected `top.v` bugs are caught by the testbench.
- **Bug found and fixed (BUG-001):** in `top.v` the write data and write enable were registered but the write
  address was not, so `RAM[A]` held `ROM[A-1]`. A registered write address (`wr_addr_reg`) fixes it; the system
  tests went from 0 of 3 to 3 of 3 passing.

**How to run** (needs Vivado 2025.2 at `/opt/Xilinx/2025.2`, `make` and GTKWave in WSL)
```
cd sim
make regress             # dpram block-level regression (12 runs)
make TEST=full_test      # one block-level test, prints the coverage line
make sys_regress_all     # top.v system tests, real ROM then scrambled ROM
bash mutate.sh           # mutation test of dpram.v   (bash mutate_sys.sh for top.v)
make wave                # open the last waveform in GTKWave
make clean               # delete all generated files
```

**Verification layout**
```
docs/   spec.md, test_plan.md, bug_log.md
sim/    Makefile, file lists, regress*.list/.sh, mutate*.sh, mutants/, mutants_sys/
verif/  interfaces/  agents/{wr_agent,rd_agent}/  env/  sequences/  tests/  sva/  tb/  sys/
```

---

## 🚀 Key Features
- True dual-port RAM architecture
- Independent read and write clocks
- ROM-based self-testing mechanism
- Modular and reusable Verilog design
- Fully synthesizable for FPGA implementation

---

## 📚 Applications
- FIFO memory systems
- On-chip buffering
- FPGA memory interface verification
- Digital design and VLSI academic projects

---

## ✅ Conclusion
This project demonstrates a **robust dual-port memory system** with ROM-controlled self-test logic. It provides practical exposure to **clock-domain separation, memory interfacing, and FPGA-based on-chip memory design**.

---
