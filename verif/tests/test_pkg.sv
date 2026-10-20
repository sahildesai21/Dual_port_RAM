package test_pkg;
    import uvm_pkg::*;
    import wr_pkg::*;
    import rd_pkg::*;
    import env_pkg::*;
    `include "uvm_macros.svh"
    `include "base_test.sv"
    `include "write_read_test.sv"
    `include "back_to_back_test.sv"
    `include "collision_test.sv"
    `include "reset_test.sv"
    `include "reset_traffic_test.sv"
    `include "random_test.sv"
    `include "full_test.sv"
endpackage
