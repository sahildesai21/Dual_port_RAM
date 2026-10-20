// T06 (reset clears q), T07 (writes ignored during reset), T08 (reset keeps memory)
class reset_test extends base_test;
    `uvm_component_utils(reset_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        wr_sweep_seq  fill = wr_sweep_seq::type_id::create("fill");
        rd_single_seq r10  = rd_single_seq::type_id::create("r10");
        wr_single_seq w10  = wr_single_seq::type_id::create("w10");
        rd_sweep_seq  chk  = rd_sweep_seq::type_id::create("chk");

        // 1. fill the memory with known data
        fill.start(env.wr_ag.sqr);

        // 2. point the read port at address 10 (nonzero data), so q is nonzero before reset
        r10.s_addr = 10;
        r10.start(env.rd_ag.sqr);

        // 3. reset for 6 clocks; the write to address 10 is started 3 clocks in, so it is
        //    really sampled while rst=1: q must read 0 during reset (T06), and the write
        //    must be ignored (T07)
        w10.s_addr = 10;  w10.s_data = 8'hEE;
        fork
            rst_vif.pulse(6);
            begin
                repeat (3) @(posedge rst_vif.clk);   // reset is already high
                w10.start(env.wr_ag.sqr);            // write attempted during reset
            end
        join

        // 4. memory must still hold the old data, address 10 included (T08)
        chk.start(env.rd_ag.sqr);
    endtask
endclass
