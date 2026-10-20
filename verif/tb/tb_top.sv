`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_top;
    import uvm_pkg::*;
    import test_pkg::*;

    // clock half-periods in ns; override at run time with
    //   -testplusarg WR_HALF=7.5  -testplusarg RD_HALF=5   (defaults: both 5 ns = 100 MHz)
    real wr_half = 5.0;
    real rd_half = 5.0;

    logic write_clock, read_clock;

    // clocks
    initial begin
        write_clock = 0;
        if (!$value$plusargs("WR_HALF=%f", wr_half)) wr_half = 5.0;
        forever #(wr_half) write_clock = ~write_clock;
    end
    initial begin
        read_clock = 0;
        if (!$value$plusargs("RD_HALF=%f", rd_half)) rd_half = 5.0;
        forever #(rd_half) read_clock = ~read_clock;
    end
    initial begin
        #1;   // after both plusargs are read
        $display("TB_CLK write_half=%0.2fns read_half=%0.2fns", wr_half, rd_half);
    end

    // reset interface: tests can pulse it later through rst_vif
    rst_if rsti (.clk(write_clock));

    // initial reset: high for 5 write clocks, released 1ns after an edge (no race with the DUT)
    initial begin
        rsti.rst = 1;
        repeat (5) @(posedge write_clock);
        #1 rsti.rst = 0;
    end

    // interfaces
    wr_if wif (.write_clock(write_clock), .rst(rsti.rst));
    rd_if rif (.read_clock(read_clock), .rst(rsti.rst));

    // DUT
    dpram #(.DATA_WIDTH(8), .ADDR_WIDTH(6)) dut (
        .data        (wif.data),
        .read_addr   (rif.read_addr),
        .write_addr  (wif.write_addr),
        .we          (wif.we),
        .read_clock  (read_clock),
        .write_clock (write_clock),
        .rst         (rsti.rst),
        .q           (rif.q)
    );

    // hand the virtual interfaces to UVM, then start the test
    initial begin
        uvm_config_db#(virtual wr_if)::set(null, "*", "wr_vif", wif);
        uvm_config_db#(virtual rd_if)::set(null, "*", "rd_vif", rif);
        uvm_config_db#(virtual rst_if)::set(null, "*", "rst_vif", rsti);
        run_test();
    end

    initial begin
        $dumpfile("dpram.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
