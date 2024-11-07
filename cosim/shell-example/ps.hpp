#ifndef PS_HPP
#define PS_HPP

#define GP0_RD_CSR_0 GP0_RD_PS2PL_CSR_ADDR_BASE
#define GP0_RD_CSR_1 (GP0_RD_CSR_0 + 0x4)
#define GP0_RD_CSR_2 (GP0_RD_CSR_1 + 0x4)
#define GP0_RD_CSR_3 (GP0_RD_CSR_2 + 0x4)

#define GP0_RD_CSR_4 GP0_RD_PL2PS_CSR_ADDR_BASE

#define GP0_WR_CSR_0 GP0_WR_PS2PL_CSR_ADDR_BASE
#define GP0_WR_CSR_1 (GP0_WR_CSR_0 + 0x4)
#define GP0_WR_CSR_2 (GP0_WR_CSR_1 + 0x4)
#define GP0_WR_CSR_3 (GP0_WR_CSR_2 + 0x4)

#define GP0_WR_FIFO_0_DATA GP0_WR_PS2PL_FIFO_DATA_BASE
#define GP0_WR_FIFO_1_DATA (GP0_WR_FIFO_0_DATA + 0x4)
#define GP0_WR_FIFO_2_DATA (GP0_WR_FIFO_1_DATA + 0x4)
#define GP0_WR_FIFO_3_DATA (GP0_WR_FIFO_2_DATA + 0x4)

#define GP0_RD_FIFO_0_CTRS GP0_RD_PS2PL_FIFO_CTRS_BASE
#define GP0_RD_FIFO_1_CTRS (GP0_RD_FIFO_0_CTRS + 0x4)
#define GP0_RD_FIFO_2_CTRS (GP0_RD_FIFO_1_CTRS + 0x4)
#define GP0_RD_FIFO_3_CTRS (GP0_RD_FIFO_2_CTRS + 0x4)

#define GP0_RD_FIFO_4_DATA GP0_RD_PL2PS_FIFO_DATA_BASE
#define GP0_RD_FIFO_5_DATA (GP0_RD_FIFO_4_DATA + 0x4)

#define GP0_RD_FIFO_4_CTRS GP0_RD_PL2PS_FIFO_CTRS_BASE
#define GP0_RD_FIFO_5_CTRS (GP0_RD_FIFO_4_CTRS + 0x4)

#endif

