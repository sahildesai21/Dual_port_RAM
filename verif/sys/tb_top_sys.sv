`timescale 1ns/1ps
`include "uvm_macros.svh"

// System-level testbench: the whole top.v (counters + ROM + DPRAM + adder)
module tb_top_sys;
    import uvm_pkg::*;
    import sys_pkg::*;

    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    sys_if sif (.clk(clk));

    // reset asserted from time 0 so the DUT starts in a known state
    initial begin
        sif.rst = 1'b1;
        sif.en  = 1'b0;
    end

    top dut (
        .clk       (clk),
        .rst       (sif.rst),
        .en        (sif.en),
        .up_addr   (sif.up_addr),
        .down_addr (sif.down_addr),
        .rom_out   (sif.rom_out),
        .ram_out   (sif.ram_out),
        .sum_out   (sif.sum_out)
    );

    initial begin
        uvm_config_db#(virtual sys_if)::set(null, "*", "sys_vif", sif);
        run_test();
    end

    initial begin
        $dumpfile("dpram.vcd");
        $dumpvars(0, tb_top_sys);
    end
endmodule
