
#ifndef ZYNQ_HEADERS_H
#define ZYNQ_HEADERS_H

#define _STRINGIFY(x) #x
#define STRINGIFY(x) _STRINGIFY(x)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef GP0_ENABLE
#define GP0_ADDR_WIDTH 0
#define GP0_DATA_WIDTH 0
#define GP0_ADDR_BASE 0
#define GP0_HIER_BASE ""
#endif

#ifndef GP0_ADDR_WIDTH
#error GP0_ADDR_WIDTH must be defined
#endif
#ifndef GP0_ADDR_SIZE_BYTES
#define GP0_ADDR_SIZE_BYTES (1 << GP0_ADDR_WIDTH)
#endif
static uintptr_t gp0_addr_size_bytes = (uintptr_t) GP0_ADDR_SIZE_BYTES;

#ifndef GP0_ADDR_BASE
#error GP0_ADDR_BASE must be defined
#endif
static uintptr_t gp0_addr_base = (uintptr_t) GP0_ADDR_BASE;

#ifndef GP0_DATA_WIDTH
#error GP0_DATA_WIDTH must be defined
#endif

#ifndef GP0_HIER_BASE
#ifndef FPGA
#error GP0_HIER_BASE must be defined
#endif
#endif

#ifndef GP1_ENABLE
#define GP1_ADDR_WIDTH 0
#define GP1_DATA_WIDTH 0
#define GP1_ADDR_BASE 0
#define GP1_HIER_BASE ""
#endif

#ifndef GP1_ADDR_WIDTH
#error GP1_ADDR_WIDTH must be defined
#endif
#ifndef GP1_ADDR_SIZE_BYTES
#define GP1_ADDR_SIZE_BYTES (1 << GP1_ADDR_WIDTH)
#endif
static uintptr_t gp1_addr_size_bytes = (uintptr_t) GP1_ADDR_SIZE_BYTES;

#ifndef GP1_ADDR_BASE
#error GP1_ADDR_BASE must be defined
#endif
static uintptr_t gp1_addr_base = (uintptr_t) GP1_ADDR_BASE;

#ifndef GP1_DATA_WIDTH
#error GP1_DATA_WIDTH must be defined
#endif

#ifndef GP1_HIER_BASE
#ifndef FPGA
#error GP1_HIER_BASE must be defined
#endif
#endif

#ifndef GP2_ENABLE
#define GP2_ADDR_WIDTH 0
#define GP2_DATA_WIDTH 0
#define GP2_ADDR_BASE 0
#define GP2_HIER_BASE ""
#endif

#ifndef GP2_ADDR_WIDTH
#error GP2_ADDR_WIDTH must be defined
#endif
#ifndef GP2_ADDR_SIZE_BYTES
#define GP2_ADDR_SIZE_BYTES (1 << GP2_ADDR_WIDTH)
#endif

#ifndef GP2_ADDR_BASE
#error GP2_ADDR_BASE must be defined
#endif

#ifndef GP2_DATA_WIDTH
#error GP2_DATA_WIDTH must be defined
#endif

#ifndef GP2_HIER_BASE
#error GP2_HIER_BASE must be defined
#endif

#ifndef HP0_ENABLE
#define HP0_ADDR_WIDTH 0 
#define HP0_DATA_WIDTH 0
#define HP0_ADDR_BASE 0
#define HP0_HIER_BASE ""
#endif

#ifndef HP0_ADDR_WIDTH
#error HP0_ADDR_WIDTH must be defined
#endif
#ifndef HP0_ADDR_SIZE_BYTES
#define HP0_ADDR_SIZE_BYTES (1 << HP0_ADDR_WIDTH)
#endif
static uintptr_t hp0_addr_size_bytes = (uintptr_t) HP0_ADDR_SIZE_BYTES;

#ifndef HP0_ADDR_BASE
#error HP0_ADDR_BASE must be defined
#endif
static uintptr_t hp0_addr_base = (uintptr_t) HP0_ADDR_BASE;

#ifndef HP0_DATA_WIDTH
#error HP0_DATA_WIDTH must be defined
#endif

#ifndef HP0_HIER_BASE
#ifndef FPGA
#error HP0_HIER_BASE must be defined
#endif
#endif

#endif

