#ifndef PS_HPP

#define GP0_RD_CSR_DRAM_BASE_ADDR   (GP0_ADDR_BASE                  )
#define GP0_RD_CSR_NULL             (GP0_RD_CSR_DRAM_BASE_ADDR + 0x4)
#define GP0_RD_PL2PS_FIFO_DATA      (GP0_RD_CSR_NULL           + 0x4)
#define GP0_RD_PL2PS_FIFO_CTRS      (GP0_RD_PL2PS_FIFO_DATA    + 0x4)
#define GP0_RD_PS2PL_FIFO_CTRS      (GP0_RD

#define GP0_WR_CSR_DRAM_BASE_ADDR   GP0_RD_CSR_DRAM_BASE_ADDR
i

#define GP0_RD_CSR_SYS_RESETN    (GP0_ADDR_BASE                 )
#define GP0_RD_CSR_TAG_BITBANG   (GP0_RD_CSR_SYS_RESETN    + 0x4)
#define GP0_RD_CSR_DRAM_INITED   (GP0_RD_CSR_TAG_BITBANG   + 0x4)
#define GP0_RD_CSR_DRAM_BASE     (GP0_RD_CSR_DRAM_INITED   + 0x4)
#define GP0_RD_CSR_BOOTROM_ADDR  (GP0_RD_CSR_DRAM_BASE     + 0x4)
#define GP0_RD_PL2PS_FIFO_DATA   (GP0_RD_CSR_BOOTROM_ADDR  + 0x4)
#define GP0_RD_PL2PS_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_DATA   + 0x4)
#define GP0_RD_PS2PL_FIFO_CTRS   (GP0_RD_PL2PS_FIFO_CTRS   + 0x4)
#define GP0_RD_MINSTRET          (GP0_RD_PS2PL_FIFO_CTRS   + 0x4)
#define GP0_RD_MINSTRET_0        (GP0_RD_MINSTRET               )
#define GP0_RD_MINSTRET_1        (GP0_RD_MINSTRET_0        + 0x4)
#define GP0_RD_MEM_PROF_0        (GP0_RD_MINSTRET_1        + 0x4)
#define GP0_RD_MEM_PROF_1        (GP0_RD_MEM_PROF_0        + 0x4)
#define GP0_RD_MEM_PROF_2        (GP0_RD_MEM_PROF_1        + 0x4)
#define GP0_RD_MEM_PROF_3        (GP0_RD_MEM_PROF_2        + 0x4)
#define GP0_RD_BOOTROM_DATA      (GP0_RD_MEM_PROF_3        + 0x4)

// GP0 Write Memory Map
#define GP0_WR_CSR_SYS_RESETN    GP0_RD_CSR_SYS_RESETN
#define GP0_WR_CSR_TAG_BITBANG   GP0_RD_CSR_TAG_BITBANG
#define GP0_WR_CSR_DRAM_INITED   GP0_RD_CSR_DRAM_INITED
#define GP0_WR_CSR_DRAM_BASE     GP0_RD_CSR_DRAM_BASE
#define GP0_WR_CSR_BOOTROM_ADDR  GP0_RD_CSR_BOOTROM_ADDR
#define GP0_WR_PS2PL_FIFO_DATA   (GP0_WR_CSR_BOOTROM_ADDR + 0x4)


#endif

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:
   //
   // 0: dram_base_addr
   //
   // c: bootrom addr
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0 : NULL
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_li;

   ///////////////////////////////////////////////////////////////////////////////////////
   // pl_to_ps_fifo_data_li:
   //
   // 0: DRAM response
   logic [num_fifos_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   logic [num_fifos_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li,                      pl_to_ps_fifo_ready_lo;


   ///////////////////////////////////////////////////////////////////////////////////////
   // ps_to_pl_fifo_data_lo:
   //
   // 0: DRAM request TYPE (0 = write, 1 = read)
   // 4: DRAM request ADDR
   // 8: DRAM request DATA
   logic [num_fifos_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   logic [num_fifos_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo,                      ps_to_pl_fifo_yumi_li;
