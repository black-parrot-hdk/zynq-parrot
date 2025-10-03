#ifndef PS_HPP

// GP0 Read Memory Map
#define GP0_RD_CSR_DRAM_BASE        (GP0_ADDR_BASE                  )
#define GP0_RD_PL2PS_FIFO_DATA0     (GP0_RD_CSR_DRAM_BASE      + 0x4)
#define GP0_RD_PL2PS_FIFO_CTR0      (GP0_RD_PL2PS_FIFO_DATA0   + 0x4)
#define GP0_RD_PS2PL_FIFO_CTR0      (GP0_RD_PL2PS_FIFO_CTR0    + 0x4)
#define GP0_RD_PS2PL_FIFO_CTR1      (GP0_RD_PL2PS_FIFO_CTR0    + 0x4)
#define GP0_RD_PS2PL_FIFO_CTR2      (GP0_RD_PL2PS_FIFO_CTR1    + 0x4)
#define GP0_RD_CSR_NULL             (GP0_RD_PS2PL_FIFO_CTR2    + 0x4)

// GP0 Write Memory Map
#define GP0_WR_CSR_DRAM_BASE        (GP0_RD_CSR_DRAM_BASE         )
#define GP0_WR_PS2PL_FIFO_DATA0     (GP0_WR_CSR_DRAM_BASE    + 0x4)
#define GP0_WR_PS2PL_FIFO_DATA1     (GP0_WR_PS2PL_FIFO_DATA0 + 0x4)
#define GP0_WR_PS2PL_FIFO_DATA2     (GP0_WR_PS2PL_FIFO_DATA1 + 0x4)

#endif

