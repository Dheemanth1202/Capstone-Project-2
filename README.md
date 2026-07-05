# Systolic Array Multiplier — Verilog Implementation

A fully pipelined **NxN Systolic Array Multiplier** implemented in Verilog.  
Computes the 2N-bit unsigned product of two N-bit operands using an array of  
Processing Elements (PEs) where data flows rhythmically (systolically) through  
the array — partial products accumulate downward, carries propagate rightward.

---

## Architecture Overview

```
        B[N-1]  B[N-2]  ...  B[1]  B[0]
          |       |            |     |
A[0] --> PE(0,N-1)--...--PE(0,1)--PE(0,0) --> c_out[0]
          |                   |     |
A[1] --> PE(1,N-1)--...--PE(1,1)--PE(1,0) --> c_out[1]
          |                   |     |
          :                   :     :
          |                   |     |
A[N-1]-> PE(N-1,N-1)-...-PE(N-1,1)-PE(N-1,0) --> c_out[N-1]
          |                   |     |
        product[N-1]         ...  product[0]
```

- **A bits** flow **downward** through each column.  
- **B bits** flow **rightward** through each row.  
- **Partial product sums** accumulate **downward**.  
- **Carries** propagate **rightward** within each row.

---

## Module Hierarchy

```
systolic_top
├── control_unit          FSM: IDLE → LOAD → COMPUTE → DONE
└── systolic_array        NxN grid of Processing Elements
    └── processing_element (×N²)
        ├── full_adder
        │   ├── half_adder
        │   └── half_adder
        └── register ×4   (A, B, Sum, Carry pipeline registers)
```

Supporting modules:
- `mux.v` — 2-to-1 parameterizable multiplexer (boundary/select logic)
- `register.v` — Generic D flip-flop with synchronous reset

---

## File Structure

```
Systolic_Array_Multiplier/
├── rtl/
│   ├── systolic_top.v          Top-level: CU + Array + I/O registers
│   ├── systolic_array.v        NxN PE grid wiring
│   ├── processing_element.v    Core PE: AND + FA + 4 pipeline registers
│   ├── full_adder.v            1-bit full adder (2x half adder)
│   ├── half_adder.v            1-bit half adder
│   ├── register.v              Parameterizable D flip-flop
│   ├── mux.v                   2-to-1 parameterizable mux
│   └── control_unit.v          FSM controller (4-state)
├── tb/
│   └── systolic_tb.v           Self-checking testbench (30 test vectors)
├── sim/
│   ├── run.do                  ModelSim/QuestaSim compile+sim script
│   └── waveform.vcd            Generated waveform dump (post-sim)
├── reports/
│   └── report.pdf              (Synthesis/timing report — add after P&R)
└── README.md
```

---

## Processing Element (PE) Operation

Each PE performs the following in one clock cycle:

```
and_bit       = a_in  AND  b_in
{c_out, p_out} = and_bit + p_in + c_in    (Full Adder)
a_out         = REG(a_in)                  (systolic pass-through)
b_out         = REG(b_in)                  (systolic pass-through)
```

| Signal | Direction | Meaning |
|--------|-----------|---------|
| `a_in / a_out` | Top → Bottom | Multiplicand bit propagated downward |
| `b_in / b_out` | Left → Right | Multiplier bit propagated rightward |
| `p_in / p_out` | Top → Bottom | Accumulated partial sum |
| `c_in / c_out` | Left → Right | Carry from previous column |

---

## Control Unit FSM

```
IDLE ──(start)──► LOAD ──► COMPUTE ──(cnt==LATENCY-1)──► DONE
 ▲                                                          │
 └────────────────────(start de-asserted)──────────────────┘
```

| State   | load | busy | valid_out |
|---------|------|------|-----------|
| IDLE    |  0   |  0   |     0     |
| LOAD    |  1   |  0   |     0     |
| COMPUTE |  0   |  1   |     0     |
| DONE    |  0   |  0   |     1     |

Pipeline latency = **2N − 1 clock cycles** after `start`.

---

## Simulation — Quick Start

### ModelSim / QuestaSim

```tcl
# From the project root
vsim -do sim/run.do
```

### Icarus Verilog (iverilog)

```bash
# Compile
iverilog -o sim/systolic_sim \
    rtl/half_adder.v \
    rtl/full_adder.v \
    rtl/register.v \
    rtl/mux.v \
    rtl/processing_element.v \
    rtl/control_unit.v \
    rtl/systolic_array.v \
    rtl/systolic_top.v \
    tb/systolic_tb.v

# Run
vvp sim/systolic_sim

# View waveforms
gtkwave sim/waveform.vcd
```

---

## Testbench Coverage

| # | Test Case | Operands | Expected |
|---|-----------|----------|----------|
| 1 | Zero × Zero | 0 × 0 | 0 |
| 2 | Zero × Max | 0 × 255 | 0 |
| 3 | Max × Zero | 255 × 0 | 0 |
| 4 | One × One | 1 × 1 | 1 |
| 5 | Identity A | 127 × 1 | 127 |
| 6 | Identity B | 1 × 200 | 200 |
| 7 | Max × Max | 255 × 255 | 65025 |
| 8 | Power of 2 | 16 × 16 | 256 |
| 9 | Small product | 12 × 13 | 156 |
| 10 | Boundary | 255 × 2 | 510 |
| 11-30 | Random vectors | $random | a × b |

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | `8` | Operand bit-width (array is N×N PEs) |

Change `N` in `systolic_top.v` and `systolic_tb.v` to resize the multiplier  
(e.g., N=4 for a 4-bit multiplier, N=16 for a 16-bit multiplier).

---

## Timing

| Metric | Value (N=8) |
|--------|-------------|
| Pipeline Latency | 15 clock cycles |
| Throughput | 1 result / clock (after fill) |
| PE count | 64 |
| Register count per PE | 4 |

---

## Synthesis Notes

- All flip-flops are synchronous with active-high reset.
- No asynchronous logic or latches.
- Fully synthesizable with Vivado, Quartus, Synopsys DC, etc.
- `generate` / `genvar` used for scalable PE instantiation.

---

## License

This project is provided for educational purposes.  
Feel free to modify and use in academic or personal projects.
