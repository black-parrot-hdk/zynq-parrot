/*
 * bp_common_test_pkg.sv
 *
 * This package contains extra testing configs which are not intended to be
 *   synthesized or used in production. However, they are useful for testing.
 *   This file can also be used as a template for 3rd parties wishing to
 *   synthesize extra configs without modifying the BP source directly.
 *
 */

  `include "bp_common_defines.svh"

package bp_common_pkg;

  `include "bp_common_accelerator_pkgdef.svh"
  `include "bp_common_addr_pkgdef.svh"
  `include "bp_common_host_pkgdef.svh"
  //`include "bp_common_aviary_pkgdef.svh"
  `include "bp_common_aviary_cfg_pkgdef.svh"

  localparam bp_proc_param_s bp_unicore_zynqparrot_cfg_override_p =
    '{paddr_width: 34

      ,icache_fill_width: 64

      ,dcache_fill_width: 64

      ,acache_fill_width: 64

      ,bedrock_fill_width: 64

      ,l2_data_width: 64
      ,l2_fill_width: 64
      ,l2_slices    : 1
      ,l2_banks     : 1

      ,itlb_els_4k : 16
      ,itlb_els_2m : 1
      ,itlb_els_1g : 1
      ,dtlb_els_4k : 16
      ,dtlb_els_2m : 4
      ,dtlb_els_1g : 1

      ,default : "inv"
      };
  `bp_aviary_derive_cfg(bp_unicore_zynqparrot_cfg_p
                        ,bp_unicore_zynqparrot_cfg_override_p
                        ,bp_default_cfg_p
                        );

  localparam bp_proc_param_s bp_multicore_zynqparrot_cfg_override_p =
    '{paddr_width: 34
      ,cce_type : e_cce_fsm
      ,ic_y_dim : 1

      ,icache_fill_width: 64
      ,icache_assoc:      4
      ,icache_sets:       128
      ,icache_block_width: 256

      ,dcache_fill_width: 64
      ,dcache_assoc:      4
      ,dcache_sets:       128
      ,dcache_block_width: 256

      ,acache_fill_width: 64
      ,acache_assoc:      4
      ,acache_sets:       128
      ,acache_block_width: 256

      ,bedrock_fill_width: 64
      ,bedrock_block_width: 256

      ,coh_noc_flit_width : 64
      ,mem_noc_flit_width : 64
      ,dma_noc_flit_width : 64

      ,icache_features      : (1 << e_cfg_enabled) | (1 << e_cfg_coherent)
                              | (1 << e_cfg_misaligned)
      ,dcache_features      : (1 << e_cfg_enabled)
                              | (1 << e_cfg_coherent)
                              | (1 << e_cfg_writeback)
                              | (1 << e_cfg_lr_sc)
                              | (1 << e_cfg_amo_swap)
                              | (1 << e_cfg_amo_fetch_logic)
                              | (1 << e_cfg_amo_fetch_arithmetic)
      ,l2_features          : (1 << e_cfg_enabled) | (1 << e_cfg_writeback)
                              | (1 << e_cfg_word_tracking)

      ,l2_data_width: 64
      ,l2_fill_width: 64
      ,l2_slices    : 1
      ,l2_banks     : 1
      ,l2_assoc     : 2
      ,l2_sets      : 4
      ,l2_block_width: 256

      ,itlb_els_4k : 16
      ,itlb_els_2m : 1
      ,itlb_els_1g : 1
      ,dtlb_els_4k : 16
      ,dtlb_els_2m : 4
      ,dtlb_els_1g : 1

      ,default : "inv"
      };
  `bp_aviary_derive_cfg(bp_multicore_zynqparrot_cfg_p
                        ,bp_multicore_zynqparrot_cfg_override_p
                        ,bp_default_cfg_p
                        );


  parameter bp_proc_param_s [max_cfgs-1:0] all_cfgs_gp =
  {
    bp_multicore_zynqparrot_cfg_p
    ,bp_unicore_zynqparrot_cfg_p

    // A custom BP configuration generated from Makefile
    ,bp_custom_cfg_p
    // The default BP
    ,bp_default_cfg_p
  };

  // This enum MUST be kept up to date with the parameter array above
  typedef enum bit [lg_max_cfgs-1:0]
  {
    e_bp_multicore_zynqparrot_cfg                   = 3
    ,e_bp_unicore_zynqparrot_cfg                    = 2

    // A custom BP configuration generated from `defines
    ,e_bp_custom_cfg                                = 1
    // The default BP
    ,e_bp_default_cfg                               = 0
  } bp_params_e;

  `include "bp_common_bedrock_pkgdef.svh"
  `include "bp_common_cache_pkgdef.svh"
  `include "bp_common_cache_engine_pkgdef.svh"
  `include "bp_common_cfg_bus_pkgdef.svh"
  `include "bp_common_clint_pkgdef.svh"
  `include "bp_common_core_pkgdef.svh"
  `include "bp_common_host_pkgdef.svh"
  `include "bp_common_rv64_pkgdef.svh"

endpackage

