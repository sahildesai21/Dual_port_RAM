interface rd_if (input logic read_clock, input logic rst);
    logic [7:0] q;
    logic [5:0] read_addr;

    clocking drv_cb @(posedge read_clock);
        default output #1;
        output  read_addr;
    endclocking

    clocking mon_cb @(posedge read_clock);
        default input #1step;
        input q, read_addr, rst;
    endclocking
endinterface 