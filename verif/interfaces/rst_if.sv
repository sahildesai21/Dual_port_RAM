interface rst_if (input logic clk);
    logic rst;

    // assert reset for N clocks, aligned like the initial reset (1ns after an edge)
    task automatic pulse(int unsigned cycles);
        @(posedge clk);
        #1 rst = 1;
        repeat (cycles) @(posedge clk);
        #1 rst = 0;
    endtask
endinterface