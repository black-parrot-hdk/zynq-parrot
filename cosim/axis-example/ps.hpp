
#ifndef PS_HPP
#define PS_HPP

// GP0 Read Memory Map
#define GP0_RD_CSR_TINIT         (GP0_ADDR_BASE                 )
#define GP0_RD_PL2PS_FIFO_DATA   (GP0_RD_CSR_TINIT         + 0x4)
#define GP0_RD_PL2PS_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_DATA   + 0x4)
#define GP0_RD_PS2PL_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_CTRS   + 0x4)
#define GP0_RD_CSR_TSTATUS       (GP0_RD_PS2PL_FIFO_CTRS   + 0x4)

// GP0 Write Memory Map
#define GP0_WR_CSR_TINIT         GP0_RD_CSR_TINIT
#define GP0_WR_PS2PL_FIFO_DATA   (GP0_WR_CSR_TINIT + 0x4)

#endif

