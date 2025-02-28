
#ifndef ZYNQ_HEADERS_H
#define ZYNQ_HEADERS_H

#include <cstdint>

#define _STRINGIFY(x) #x
#define STRINGIFY(x) _STRINGIFY(x)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef ZYNQ
#ifndef BRIDGE
#ifndef VIVADO
#define SIMULATION
#endif
#endif
#endif

#ifdef VCS
#define HAS_COSIM_MAIN
#endif
#ifdef XCELIUM
#define HAS_COSIM_MAIN
#endif

#ifdef NEON
#include "arm_neon.h"
#else
// Define our own since we're not running NEON
typedef uint32_t uint32x4_t[4];
#endif

#ifndef GP0_ENABLE
#define GP0_ADDR_WIDTH 0
#define GP0_DATA_WIDTH 0
#define GP0_ADDR_BASE 0
#define GP0_HIER_BASE ""
#endif

#ifndef GP0_ADDR_SIZE_BYTES
#ifndef GP0_ADDR_WIDTH
#error GP0_ADDR_WIDTH must be defined
#endif
#define GP0_ADDR_SIZE_BYTES (1ULL << GP0_ADDR_WIDTH)
#endif
static uintptr_t gp0_addr_size_bytes = (uintptr_t)GP0_ADDR_SIZE_BYTES;

#ifndef GP0_ADDR_BASE
#error GP0_ADDR_BASE must be defined
#endif
static uintptr_t gp0_addr_base = (uintptr_t)GP0_ADDR_BASE;

#ifndef GP0_DATA_WIDTH
#error GP0_DATA_WIDTH must be defined
#endif

#ifndef GP0_HIER_BASE
#ifdef SIMULATION
#error GP0_HIER_BASE must be defined
#endif
#endif

#ifndef GP0_SHELL_PS2PL_REGS
#define GP0_SHELL_PS2PL_REGS 1
#endif
#ifndef GP0_SHELL_PL2PS_REGS
#define GP0_SHELL_PL2PS_REGS 1
#endif
#ifndef GP0_SHELL_PL2PS_FIFOS
#define GP0_SHELL_PL2PS_FIFOS 1
#endif
#ifndef GP0_SHELL_PS2PL_FIFOS
#define GP0_SHELL_PS2PL_FIFOS 1
#endif
#define GP0_RD_PS2PL_CSR_ADDR_BASE  (GP0_ADDR_BASE               +                          0x0 )
#define GP0_RD_PL2PS_FIFO_DATA_BASE (GP0_RD_PS2PL_CSR_ADDR_BASE  + (GP0_SHELL_PS2PL_REGS  * 0x4))
#define GP0_RD_PL2PS_FIFO_CTRS_BASE (GP0_RD_PL2PS_FIFO_DATA_BASE + (GP0_SHELL_PL2PS_FIFOS * 0x4))
#define GP0_RD_PS2PL_FIFO_CTRS_BASE (GP0_RD_PL2PS_FIFO_CTRS_BASE + (GP0_SHELL_PL2PS_FIFOS * 0x4))
#define GP0_RD_PL2PS_CSR_ADDR_BASE  (GP0_RD_PS2PL_FIFO_CTRS_BASE + (GP0_SHELL_PS2PL_FIFOS * 0x4))
#define GP0_WR_PS2PL_CSR_ADDR_BASE  (GP0_RD_PS2PL_CSR_ADDR_BASE  +                          0x0 )
#define GP0_WR_PS2PL_FIFO_DATA_BASE (GP0_WR_PS2PL_CSR_ADDR_BASE  + (GP0_SHELL_PS2PL_REGS  * 0x4))

#ifndef GP1_ENABLE
#define GP1_ADDR_WIDTH 0
#define GP1_DATA_WIDTH 0
#define GP1_ADDR_BASE 0
#define GP1_HIER_BASE ""
#endif

#ifndef GP1_ADDR_SIZE_BYTES
#ifndef GP1_ADDR_WIDTH
#error GP1_ADDR_WIDTH must be defined
#endif
#define GP1_ADDR_SIZE_BYTES (1ULL << GP1_ADDR_WIDTH)
#endif
static uintptr_t gp1_addr_size_bytes = (uintptr_t)GP1_ADDR_SIZE_BYTES;

#ifndef GP1_ADDR_BASE
#error GP1_ADDR_BASE must be defined
#endif
static uintptr_t gp1_addr_base = (uintptr_t)GP1_ADDR_BASE;

#ifndef GP1_DATA_WIDTH
#error GP1_DATA_WIDTH must be defined
#endif

#ifndef GP1_HIER_BASE
#ifdef SIMULATION
#error GP1_HIER_BASE must be defined
#endif
#endif

#ifdef GP0_ENABLE
#define AXIL_ENABLE
#endif

#ifdef GP1_ENABLE
#define AXIL_ENABLE
#endif

#ifdef GP2_ENABLE
#define AXIL_ENABLE
#endif

#ifndef GP1_SHELL_PS2PL_REGS
#define GP1_SHELL_PS2PL_REGS 1
#endif
#ifndef GP1_SHELL_PL2PS_REGS
#define GP1_SHELL_PL2PS_REGS 1
#endif
#ifndef GP1_SHELL_PL2PS_FIFOS
#define GP1_SHELL_PL2PS_FIFOS 1
#endif
#ifndef GP1_SHELL_PS2PL_FIFOS
#define GP1_SHELL_PS2PL_FIFOS 1
#endif
#define GP1_RD_PS2PL_CSR_ADDR_BASE  (GP1_ADDR_BASE               +                          0x0 )
#define GP1_RD_PL2PS_FIFO_DATA_BASE (GP1_RD_CSR_ADDR_BASE        + (GP1_SHELL_PS2PL_REGS  * 0x4))
#define GP1_RD_PL2PS_FIFO_CTRS_BASE (GP1_RD_PL2PS_FIFO_DATA_BASE + (GP1_SHELL_PL2PS_FIFOS * 0x4))
#define GP1_RD_PS2PL_FIFO_CTRS_BASE (GP1_RD_PL2PS_FIFO_CTRS_BASE + (GP1_SHELL_PL2PS_FIFOS * 0x4))
#define GP1_RD_PL2PS_CSR_ADDR_BASE  (GP1_RD_PS2PS_FIFO_CTRS_BASE + (GP1_SHELL_PS2PL_FIFOS * 0x4))
#define GP1_WR_PS2PL_CSR_ADDR_BASE  (GP1_RD_PS2PL_CSR_ADDR_BASE  +                          0x0 )
#define GP1_WR_PS2PL_FIFO_DATA_BASE (GP1_WR_PS2PL_CSR_ADDR_BASE  + (GP1_SHELL_PS2PL_REGS  * 0x4))

#ifndef GP2_ENABLE
#define GP2_ADDR_WIDTH 0
#define GP2_DATA_WIDTH 0
#define GP2_ADDR_BASE 0
#define GP2_HIER_BASE ""
#endif

#ifndef GP2_ADDR_SIZE_BYTES
#ifndef GP2_ADDR_WIDTH
#error GP2_ADDR_WIDTH must be defined
#endif
#define GP2_ADDR_SIZE_BYTES (1ULL << GP2_ADDR_WIDTH)
#endif
static uintptr_t gp2_addr_size_bytes = (uintptr_t)GP2_ADDR_SIZE_BYTES;

#ifndef GP2_ADDR_BASE
#error GP2_ADDR_BASE must be defined
#endif
static uintptr_t gp2_addr_base = (uintptr_t)GP2_ADDR_BASE;

#ifndef GP2_DATA_WIDTH
#error GP2_DATA_WIDTH must be defined
#endif

#ifndef GP2_HIER_BASE
#ifdef SIMULATION
#error GP2_HIER_BASE must be defined
#endif
#endif

#ifndef HP0_ENABLE
#define HP0_ADDR_WIDTH 0
#define HP0_DATA_WIDTH 0
#define HP0_ADDR_BASE 0
#define HP0_HIER_BASE ""
#endif

#ifndef HP0_ADDR_SIZE_BYTES
#ifndef HP0_ADDR_WIDTH
#error HP0_ADDR_WIDTH must be defined
#endif
#define HP0_ADDR_SIZE_BYTES (1ULL << HP0_ADDR_WIDTH)
#endif
static uintptr_t hp0_addr_size_bytes = (uintptr_t)HP0_ADDR_SIZE_BYTES;

#ifndef HP0_ADDR_BASE
#error HP0_ADDR_BASE must be defined
#endif
static uintptr_t hp0_addr_base = (uintptr_t)HP0_ADDR_BASE;

#ifndef HP0_DATA_WIDTH
#error HP0_DATA_WIDTH must be defined
#endif

#ifndef HP0_HIER_BASE
#ifdef SIMULATION
#ifndef AXI_MEM_ENABLE
#error HP0_HIER_BASE must be defined
#endif
#endif
#endif

#ifndef HP1_ENABLE
#define HP1_ADDR_WIDTH 0
#define HP1_DATA_WIDTH 0
#define HP1_ADDR_BASE 0
#define HP1_HIER_BASE ""
#endif

#ifndef HP1_ADDR_SIZE_BYTES
#ifndef HP1_ADDR_WIDTH
#error HP1_ADDR_WIDTH must be defined
#endif
#define HP1_ADDR_SIZE_BYTES (1ULL << HP1_ADDR_WIDTH)
#endif
static uintptr_t hp1_addr_size_bytes = (uintptr_t)HP1_ADDR_SIZE_BYTES;

#ifndef HP1_ADDR_BASE
#error HP1_ADDR_BASE must be defined
#endif
static uintptr_t hp1_addr_base = (uintptr_t)HP1_ADDR_BASE;

#ifndef HP1_DATA_WIDTH
#error HP1_DATA_WIDTH must be defined
#endif

#ifndef HP1_HIER_BASE
#ifdef SIMULATION
#error HP1_HIER_BASE must be defined
#endif
#endif

#ifndef HP2_ENABLE
#define HP2_ADDR_WIDTH 0
#define HP2_DATA_WIDTH 0
#define HP2_ADDR_BASE 0
#define HP2_HIER_BASE ""
#endif

#ifndef HP2_ADDR_SIZE_BYTES
#ifndef HP2_ADDR_WIDTH
#error HP2_ADDR_WIDTH must be defined
#endif
#define HP2_ADDR_SIZE_BYTES (1ULL << HP2_ADDR_WIDTH)
#endif
static uintptr_t hp2_addr_size_bytes = (uintptr_t)HP2_ADDR_SIZE_BYTES;

#ifndef HP2_ADDR_BASE
#error HP2_ADDR_BASE must be defined
#endif
static uintptr_t hp2_addr_base = (uintptr_t)HP2_ADDR_BASE;

#ifndef HP2_DATA_WIDTH
#error HP2_DATA_WIDTH must be defined
#endif

#ifndef HP2_HIER_BASE
#ifdef SIMULATION
#error HP2_HIER_BASE must be defined
#endif
#endif

#ifdef SP0_ENABLE
#define AXIS_ENABLE
#endif

#ifdef SP1_ENABLE
#define AXIS_ENABLE
#endif

#ifdef SP2_ENABLE
#define AXIS_ENABLE
#endif

#ifndef SP0_ENABLE
#define SP0_DATA_WIDTH 0
#define SP0_HIER_BASE ""
#endif

#ifndef SP0_DATA_WIDTH
#error SP0_DATA_WIDTH must be defined
#endif

#ifndef SP0_HIER_BASE
#ifdef SIMULATION
#error SP0_HIER_BASE must be defined
#endif
#endif

#ifndef SP1_ENABLE
#define SP1_DATA_WIDTH 0
#define SP1_HIER_BASE ""
#endif

#ifndef SP1_DATA_WIDTH
#error SP1_DATA_WIDTH must be defined
#endif

#ifndef SP1_HIER_BASE
#ifdef SIMULATION
#error SP1_HIER_BASE must be defined
#endif
#endif

#ifndef SP2_ENABLE
#define SP2_DATA_WIDTH 0
#define SP2_HIER_BASE ""
#endif

#ifndef SP2_DATA_WIDTH
#error SP2_DATA_WIDTH must be defined
#endif

#ifndef SP2_HIER_BASE
#ifdef SIMULATION
#error SP2_HIER_BASE must be defined
#endif
#endif

#ifndef MP0_ENABLE
#define MP0_DATA_WIDTH 0
#define MP0_HIER_BASE ""
#endif

#ifndef MP0_DATA_WIDTH
#error MP0_DATA_WIDTH must be defined
#endif

#ifndef MP0_HIER_BASE
#ifdef SIMULATION
#error MP0_HIER_BASE must be defined
#endif
#endif

#ifndef MP1_ENABLE
#define MP1_DATA_WIDTH 0
#define MP1_HIER_BASE ""
#endif

#ifndef MP1_DATA_WIDTH
#error MP1_DATA_WIDTH must be defined
#endif

#ifndef MP1_HIER_BASE
#ifdef SIMULATION
#error MP1_HIER_BASE must be defined
#endif
#endif

#ifndef MP2_ENABLE
#define MP2_DATA_WIDTH 0
#define MP2_HIER_BASE ""
#endif

#ifndef MP2_DATA_WIDTH
#error MP2_DATA_WIDTH must be defined
#endif

#ifndef MP2_HIER_BASE
#ifdef SIMULATION
#error MP2_HIER_BASE must be defined
#endif
#endif

#ifndef UART_ENABLE
#define UART_DEV / dev / null
#define UART_DEV_STR ""
#define UART_BAUD 0
#else

#ifndef UART_BAUD
#ifndef SIMULATION
#error UART_BAUD must be defined
#endif
#endif

#ifndef UART_DEV
#ifndef SIMULATION
#error UART_DEV must be defined
#endif
#else
#define UART_DEV_STR STRINGIFY(UART_DEV)
#define PPCAT_NX(A, B) A##B
#define PPCAT(A, B) PPCAT_NX(A, B)
#define UART_BAUD_ENUM PPCAT(B, UART_BAUD)
#endif
#endif

#endif
