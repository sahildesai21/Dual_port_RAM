interface wr_if (input logic write_clock, input logic rst);
    logic [7:0] data;
    logic [5:0] write_addr;
    logic we;

    clocking drv_cb @(posedge write_clock);
        default output #1;
        output data, write_addr, we;
    endclocking

    clocking mon_cb @(posedge write_clock);
        default input #1step;
        input data, write_addr, we, rst;
    endclocking
endinterface 