
package bp_profiler_pkg;

  typedef struct packed
  {
    logic ic_miss;
    logic ic_l2_miss;
    logic ic_dma;
    logic branch_override;
    logic ret_override;
    logic fe_cmd;
    logic fe_cmd_fence;
    logic mispredict;
    logic control_haz;
    logic long_haz;
    logic data_haz;
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
    logic replay;
    logic exception;
    logic _interrupt;
    logic itlb_miss;
    logic dtlb_miss;
    logic dc_miss;
    logic dc_l2_miss;
    logic dc_dma;
    logic unknown;
  }  bp_stall_reason_s;

  typedef enum logic [5:0]
  {
    ic_miss              = 6'd32
    ,ic_l2_miss          = 6'd31
    ,ic_dma              = 6'd30
    ,branch_override     = 6'd29
    ,ret_override        = 6'd28
    ,fe_cmd              = 6'd27
    ,fe_cmd_fence        = 6'd26
    ,mispredict          = 6'd25
    ,control_haz         = 6'd24
    ,long_haz            = 6'd23
    ,data_haz            = 6'd22
    ,aux_dep             = 6'd21
    ,load_dep            = 6'd20
    ,mul_dep             = 6'd19
    ,fma_dep             = 6'd18
    ,sb_iraw_dep         = 6'd17
    ,sb_fraw_dep         = 6'd16
    ,sb_iwaw_dep         = 6'd15
    ,sb_fwaw_dep         = 6'd14
    ,struct_haz          = 6'd13
    ,idiv_haz            = 6'd12
    ,fdiv_haz            = 6'd11
    ,ptw_busy            = 6'd10
    ,special             = 6'd9
    ,replay              = 6'd8
    ,exception           = 6'd7
    ,_interrupt          = 6'd6
    ,itlb_miss           = 6'd5
    ,dtlb_miss           = 6'd4
    ,dc_miss             = 6'd3
    ,dc_l2_miss          = 6'd2
    ,dc_dma              = 6'd1
    ,unknown             = 6'd0
  } bp_stall_reason_e;

endpackage
