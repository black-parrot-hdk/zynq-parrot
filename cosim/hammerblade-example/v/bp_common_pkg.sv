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

  localparam bp_proc_param_s bp_unicore_hammerblade_cfg_override_p =
    '{paddr_width           : 40

      ,itlb_els_4k          : 4
      ,dtlb_els_4k          : 4
      ,itlb_els_1g          : 0
      ,dtlb_els_1g          : 4

      ,icache_sets          : 64
      ,icache_assoc         : 8
      ,icache_block_width   : 512
      ,icache_fill_width    : 64

      ,dcache_sets          : 64
      ,dcache_assoc         : 8
      ,dcache_block_width   : 512
      ,dcache_fill_width    : 64

      ,bedrock_fill_width   : 64

      ,l2_features          : 0

      // Used for carrying payload of return packets
      ,mem_noc_did_width    : 19
      ,default : "inv"
      };
  `bp_aviary_derive_cfg(bp_unicore_hammerblade_cfg_p
                        ,bp_unicore_hammerblade_cfg_override_p
                        ,bp_default_cfg_p
                        );

  localparam bp_proc_param_s bp_unicore_miniblade_cfg_override_p =
    '{l2_features               : 0

      ,branch_metadata_fwd_width: 31
      ,ras_idx_width            : 1
      ,btb_tag_width            : 6
      ,btb_idx_width            : 4
      ,bht_idx_width            : 5
      ,bht_row_els              : 2
      ,ghist_width              : 2

      ,icache_sets              : 128
      ,icache_assoc             : 1
      ,icache_block_width       : 64
      ,icache_fill_width        : 64

      ,dcache_sets              : 128
      ,dcache_assoc             : 1
      ,dcache_block_width       : 64
      ,dcache_fill_width        : 64

      ,bedrock_fill_width       : 64
      ,bedrock_block_width      : 64

      ,integer_support          : (1 << e_basic)
      ,muldiv_support           : (1 << e_idiv) | (1 << e_imul)
      ,fpu_support              : (1 << e_fma) | (1 << e_fdivsqrt)

      ,default : "inv"
      };
  `bp_aviary_derive_cfg(bp_unicore_miniblade_cfg_p
                        ,bp_unicore_miniblade_cfg_override_p
                        ,bp_unicore_hammerblade_cfg_p
                        );

  parameter bp_proc_param_s [max_cfgs-1:0] all_cfgs_gp =
  {
    bp_unicore_miniblade_cfg_p
    ,bp_unicore_hammerblade_cfg_p

    // A custom BP configuration generated from Makefile
    ,bp_custom_cfg_p
    // The default BP
    ,bp_default_cfg_p
  };

  // This enum MUST be kept up to date with the parameter array above
  typedef enum bit [lg_max_cfgs-1:0]
  {
    e_bp_unicore_miniblade_cfg                      = 3
    ,e_bp_unicore_hammerblade_cfg                   = 2

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

