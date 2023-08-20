#ifndef PS_HPP
#define PS_HPP

// GP0 Read Memory Map
#define GP0_RD_CSR_SYS_RESETN    (GP0_ADDR_BASE                 )
#define GP0_RD_CSR_DRAM_INITED   (GP0_RD_CSR_SYS_RESETN  + 0x4  )
#define GP0_RD_CSR_DRAM_BASE     (GP0_RD_CSR_DRAM_INITED + 0x4  )
#define GP0_RD_PL2PS_FIFO_DATA   (GP0_RD_CSR_DRAM_BASE   + 0x4  )
#define GP0_RD_PL2PS_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_DATA + 0x4*2)
#define GP0_RD_PS2PL_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_CTRS + 0x4*2)
#define GP0_RD_CREDITS           (GP0_RD_PS2PL_FIFO_CTRS + 0x4*2)
#define GP0_RD_MINSTRET          (GP0_RD_CREDITS         + 0x4  )
#define GP0_RD_MINSTRET_0        (GP0_RD_MINSTRET               )
#define GP0_RD_MINSTRET_1        (GP0_RD_MINSTRET_0      + 0x4  )
#define GP0_RD_MEM_PROF_0        (GP0_RD_MINSTRET_1      + 0x4  )
#define GP0_RD_MEM_PROF_1        (GP0_RD_MEM_PROF_0      + 0x4  )
#define GP0_RD_MEM_PROF_2        (GP0_RD_MEM_PROF_1      + 0x4  )
#define GP0_RD_MEM_PROF_3        (GP0_RD_MEM_PROF_2      + 0x4  )

// GP0 Write Memory Map
#define GP0_WR_CSR_SYS_RESETN    GP0_RD_CSR_SYS_RESETN
#define GP0_WR_CSR_DRAM_INITED   GP0_RD_CSR_DRAM_INITED
#define GP0_WR_CSR_DRAM_BASE     GP0_RD_CSR_DRAM_BASE
#define GP0_WR_PS2PL_FIFO_DATA   (GP0_WR_CSR_DRAM_BASE + 0x4)

// DRAM
#define DRAM_BASE_ADDR  0x80000000U
#define DRAM_MAX_ALLOC_SIZE 0x20000000U

// BP
#define BP_MTIME    0x30bff8
#define BP_MTIMECMP 0x304000

#endif
