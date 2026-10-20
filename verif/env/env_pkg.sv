package env_pkg;
    import uvm_pkg::*;
    import wr_pkg::*;
    import rd_pkg::*;
    `include "uvm_macros.svh"

    `include "dpram_env_cfg.sv"
    `include "dpram_scoreboard.sv"
    `include "dpram_coverage.sv"
    `include "dpram_vseqr.sv"
    `include "dpram_vseq_lib.sv"
    `include "dpram_env.sv"
endpackage
