
package bp_profiler_pkg;

  typedef struct packed
  {
    logic icache_miss;
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
    logic dcache_miss;
    logic l2_miss;
    logic dma;
    logic unknown;
  }  bp_stall_reason_s;

  typedef enum logic [4:0]
  {
    icache_miss          = 5'd30
    ,branch_override     = 5'd29
    ,ret_override        = 5'd28
    ,fe_cmd              = 5'd27
    ,fe_cmd_fence        = 5'd26
    ,mispredict          = 5'd25
    ,control_haz         = 5'd24
    ,long_haz            = 5'd23
    ,data_haz            = 5'd22
    ,aux_dep             = 5'd21
    ,load_dep            = 5'd20
    ,mul_dep             = 5'd19
    ,fma_dep             = 5'd18
    ,sb_iraw_dep         = 5'd17
    ,sb_fraw_dep         = 5'd16
    ,sb_iwaw_dep         = 5'd15
    ,sb_fwaw_dep         = 5'd14
    ,struct_haz          = 5'd13
    ,idiv_haz            = 5'd12
    ,fdiv_haz            = 5'd11
    ,ptw_busy            = 5'd10
    ,special             = 5'd9
    ,replay              = 5'd8
    ,exception           = 5'd7
    ,_interrupt          = 5'd6
    ,itlb_miss           = 5'd5
    ,dtlb_miss           = 5'd4
    ,dcache_miss         = 5'd3
    ,l2_miss             = 5'd2
    ,dma                 = 5'd1
    ,unknown             = 5'd0
  } bp_stall_reason_e;

endpackage
