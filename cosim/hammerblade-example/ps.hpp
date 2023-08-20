#ifndef PS_HPP
#define PS_HPP

// GP0 Read Memory Map
#define GP0_RD_CSR_SYS_RESETN    (GP0_ADDR_BASE                   )
#define GP0_RD_CSR_TAG_BITBANG   (GP0_RD_CSR_SYS_RESETN    + 0x4  )
#define GP0_RD_CSR_DRAM_INITED   (GP0_RD_CSR_TAG_BITBANG   + 0x4  )
#define GP0_RD_CSR_DRAM_BASE     (GP0_RD_CSR_DRAM_INITED   + 0x4  )
#define GP0_RD_CSR_ROM_ADDR      (GP0_RD_CSR_DRAM_BASE     + 0x4  )
#define GP0_RD_MC_REQ_FIFO_DATA  (GP0_RD_CSR_ROM_ADDR      + 0x4  )
#define GP0_RD_MC_RSP_FIFO_DATA  (GP0_RD_MC_REQ_FIFO_DATA  + 0x4  )
#define GP0_RD_MC_REQ_FIFO_CTR   (GP0_RD_MC_RSP_FIFO_DATA  + 0x4  )
#define GP0_RD_MC_RSP_FIFO_CTR   (GP0_RD_MC_REQ_FIFO_CTR   + 0x4  )
#define GP0_RD_EP_REQ_FIFO_CTR   (GP0_RD_MC_RSP_FIFO_CTR   + 0x4  )
#define GP0_RD_EP_RSP_FIFO_CTR   (GP0_RD_EP_REQ_FIFO_CTR   + 0x4  )
#define GP0_RD_CREDIT_COUNT      (GP0_RD_EP_RSP_FIFO_CTR   + 0x4  )
#define GP0_RD_ROM_DATA          (GP0_RD_CREDIT_COUNT      + 0x4  )

// GP0 Write Memory Map
#define GP0_WR_CSR_SYS_RESETN     GP0_RD_CSR_SYS_RESETN
#define GP0_WR_CSR_TAG_BITBANG    GP0_RD_CSR_TAG_BITBANG
#define GP0_WR_CSR_DRAM_INITED    GP0_RD_CSR_DRAM_INITED
#define GP0_WR_CSR_DRAM_BASE      GP0_RD_CSR_DRAM_BASE
#define GP0_WR_CSR_ROM_ADDR       GP0_RD_CSR_ROM_ADDR
#define GP0_WR_EP_REQ_FIFO_DATA  (GP0_WR_CSR_ROM_ADDR + 0x4)
#define GP0_WR_EP_RSP_FIFO_DATA  (GP0_WR_EP_REQ_FIFO_DATA + 0x4)

#define TAG_NUM_CLIENTS 16
#define TAG_MAX_LEN 1
#define TAG_CLIENT_MC_RESET_ID 0
#define TAG_CLIENT_MC_RESET_WIDTH 1

#endif
