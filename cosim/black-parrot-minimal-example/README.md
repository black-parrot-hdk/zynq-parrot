# BlackParrot Minimal Cosimulation Example

This example demonstrates cosimulation of the BlackParrot RISC-V processor
in the ZynqParrot framework, using Verilator.

## CSR Register Map

### PS to PL (host writes)
| Offset | Description |
|--------|-------------|
| 0 | System reset (active low) |
| 1 | DRAM initialized flag |
| 2 | DRAM base address |
| 3 | Bootrom address |
| 4-8 | IRQ signals (debug, timer, software, m_external, s_external) |
| 9 | Freeze signal |

### PL to PS (host reads)
| Offset | Description |
|--------|-------------|
| 0 | BP I/O credits used |
| 1 | minstret[31:0] - instructions retired (lower 32 bits) |
| 2 | minstret[63:32] - instructions retired (upper 32 bits) |
| 3 | Bootrom read data |

## Instrumentation Note
minstret is probed directly from the BlackParrot pipeline using hierarchical
references, which is supported in Verilator, VCS, and Vivado but not in ASIC flows.
