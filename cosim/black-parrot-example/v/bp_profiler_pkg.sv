
package bp_profiler_pkg;

  typedef struct packed {
    logic ic_miss;
    logic br_ovr;
    logic ret_ovr;
    logic jal_ovr;
    logic fe_cmd;
    logic fe_cmd_fence;
    logic mispredict;
    logic control_haz;
    logic long_haz;
    logic data_haz;
    logic catchup_dep;
    logic aux_dep;
    logic load_dep;
    logic mul_dep;
    logic fma_dep;
    logic sb_iraw_dep;
    logic sb_fraw_dep;
    logic sb_iwaw_dep;
    logic sb_fwaw_dep;
    logic struct_haz;
    logic idiv_haz;
    logic fdiv_haz;
    logic ptw_busy;
    logic special;
    logic exception;
    logic _interrupt;
    logic itlb_miss;
    logic dtlb_miss;
    logic dc_miss;
    logic dc_fail;
    logic unknown;
  } bp_stall_reason_s;

  typedef enum logic [5:0] {
    ic_miss
    ,br_ovr      
    ,ret_ovr
    ,jal_ovr
    ,fe_cmd
    ,fe_cmd_fence
    ,mispredict
    ,control_haz
    ,long_haz
    ,data_haz
    ,catchup_dep
    ,aux_dep
    ,load_dep
    ,mul_dep
    ,fma_dep
    ,sb_iraw_dep
    ,sb_fraw_dep
    ,sb_iwaw_dep
    ,sb_fwaw_dep
    ,struct_haz
    ,idiv_haz
    ,fdiv_haz
    ,ptw_busy
    ,special
    ,exception
    ,_interrupt
    ,itlb_miss
    ,dtlb_miss
    ,dc_miss
    ,dc_fail
    ,unknown
  } bp_stall_reason_e;

  typedef struct packed {
    logic e_ic_req_cnt;
    logic e_ic_miss_cnt;
    logic e_ic_miss;
    logic e_dc_req_cnt;
    logic e_dc_miss_cnt;
    logic e_dc_miss;

    logic e_ic_miss_l2_ic;
    logic e_ic_miss_l2_dfetch;
    logic e_ic_miss_l2_devict;
    logic e_dc_miss_l2_ic;
    logic e_dc_miss_l2_dfetch;
    logic e_dc_miss_l2_devict;

    logic e_l2_ic_cnt;
    logic e_l2_dfetch_cnt;
    logic e_l2_devict_cnt;
    logic e_l2_ic;
    logic e_l2_dfetch;
    logic e_l2_devict;

    logic e_l2_ic_miss_cnt;
    logic e_l2_dfetch_miss_cnt;
    logic e_l2_devict_miss_cnt;
    logic e_l2_ic_miss;
    logic e_l2_dfetch_miss;
    logic e_l2_devict_miss;

    logic e_l2_ic_dma;
    logic e_l2_dfetch_dma;
    logic e_l2_devict_dma;

    logic e_wdma_ic_cnt;
    logic e_rdma_ic_cnt;
    logic e_wdma_ic;
    logic e_rdma_ic;
    logic e_dma_ic;

    logic e_wdma_dfetch_cnt;
    logic e_rdma_dfetch_cnt;
    logic e_wdma_dfetch;
    logic e_rdma_dfetch;
    logic e_dma_dfetch;

    logic e_wdma_devict_cnt;
    logic e_wdma_devict;
  } bp_event_reason_s;

  typedef enum logic [5:0] {
    e_ic_req_cnt
    ,e_ic_miss_cnt
    ,e_ic_miss
    ,e_dc_req_cnt
    ,e_dc_miss_cnt
    ,e_dc_miss

    ,e_ic_miss_l2_ic
    ,e_ic_miss_l2_dfetch
    ,e_ic_miss_l2_devict
    ,e_dc_miss_l2_ic
    ,e_dc_miss_l2_dfetch
    ,e_dc_miss_l2_devict

    ,e_l2_ic_cnt
    ,e_l2_dfetch_cnt
    ,e_l2_devict_cnt
    ,e_l2_ic
    ,e_l2_dfetch
    ,e_l2_devict

    ,e_l2_ic_miss_cnt
    ,e_l2_dfetch_miss_cnt
    ,e_l2_devict_miss_cnt
    ,e_l2_ic_miss
    ,e_l2_dfetch_miss
    ,e_l2_devict_miss

    ,e_l2_ic_dma
    ,e_l2_dfetch_dma
    ,e_l2_devict_dma

    ,e_wdma_ic_cnt
    ,e_rdma_ic_cnt
    ,e_wdma_ic
    ,e_rdma_ic
    ,e_dma_ic

    ,e_wdma_dfetch_cnt
    ,e_rdma_dfetch_cnt
    ,e_wdma_dfetch
    ,e_rdma_dfetch
    ,e_dma_dfetch

    ,e_wdma_devict_cnt
    ,e_wdma_devict
  } bp_event_reason_e;

endpackage
