// T01 (single write/read), T04 (overwrite), T02 (full sweep of all 64 addresses)
class write_read_test extends base_test;
    `uvm_component_utils(write_read_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        wr_single_seq w1    = wr_single_seq::type_id::create("w1");
        wr_single_seq w2    = wr_single_seq::type_id::create("w2");
        rd_single_seq r5    = rd_single_seq::type_id::create("r5");
        wr_sweep_seq  wsw   = wr_sweep_seq::type_id::create("wsw");
        rd_sweep_seq  rsw   = rd_sweep_seq::type_id::create("rsw");

        // T01: one write, one read (defaults: address 3, data 0xA5)
        super.body();

        // T04: overwrite the same address, read must return the newer value
        w1.s_addr = 5;  w1.s_data = 8'h11;
        w2.s_addr = 5;  w2.s_data = 8'h22;
        r5.s_addr = 5;
        w1.start(env.wr_ag.sqr);
        w2.start(env.wr_ag.sqr);
        r5.start(env.rd_ag.sqr);

        // T02: fill all 64 locations, then read them all back
        wsw.start(env.wr_ag.sqr);
        rsw.start(env.rd_ag.sqr);
    endtask
endclass
