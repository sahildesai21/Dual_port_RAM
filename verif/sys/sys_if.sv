// Interface to top.v: two control inputs (rst, en) and the five monitor outputs.
interface sys_if (input logic clk);
    logic       rst;
    logic       en;
    logic [7:0] up_addr;
    logic [7:0] down_addr;
    logic [7:0] rom_out;
    logic [7:0] ram_out;
    logic [7:0] sum_out;

    // driver: changes rst/en 1ns after the clock edge
    clocking drv_cb @(posedge clk);
        default output #1;
        output rst, en;
    endclocking

    // monitor: samples everything just before the clock edge
    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst, en, up_addr, down_addr, rom_out, ram_out, sum_out;
    endclocking
endinterface
