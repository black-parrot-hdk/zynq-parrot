#ifndef PS_HPP
#define PS_HPP

// GP0 Read Memory Map
#define GP0_RD_CSR_NONE         (GP0_ADDR_BASE                 )
#define GP0_RD_PL2PS_FIFO_DATA  (GP0_RD_CSR_NONE          + 0x4)
#define GP0_RD_PL2PS_FIFO_CTRS  (GP0_RD_PL2PS_FIFO_DATA   + 0x4)
#define GP0_RD_PS2PL_FIFO_CTRS  (GP0_RD_PL2PS_FIFO_CTRS   + 0x4)
#define GP0_RD_CSR_LAST_ADDR    (GP0_RD_PS2PL_FIFO_CTRS   + 0x4)

// GP0 Write Memory Map
#define GP0_WR_CSR_NONE          GP0_RD_CSR_NONE
#define GP0_WR_PS2PL_FIFO_DATA   (GP0_WR_CSR_NONE+ 0x4)

#endif

