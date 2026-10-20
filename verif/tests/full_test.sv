// Runs every scenario in one simulation, so coverage can be measured as a whole
class full_test extends base_test;
    `uvm_component_utils(full_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        wr_sweep_seq          wsw  = wr_sweep_seq::type_id::create("wsw");
        rd_sweep_seq          rsw  = rd_sweep_seq::type_id::create("rsw");
        dpram_collision_vseq  col  = dpram_collision_vseq::type_id::create("col");
        dpram_concurrent_vseq conc = dpram_concurrent_vseq::type_id::create("conc");
        wr_single_seq         w10  = wr_single_seq::type_id::create("w10");
        rd_single_seq         r10  = rd_single_seq::type_id::create("r10");
        bit [7:0]             pats[4] = '{8'h00, 8'hFF, 8'hAA, 8'h55};

        // 1. one write, one read
        super.body();

        // 2. every write and read address
        wsw.start(env.wr_ag.sqr);
        rsw.start(env.rd_ag.sqr);

        // 3. data patterns the sweep never produces: 00, FF, AA, 55 (written, then read back)
        foreach (pats[i]) begin
            wr_single_seq w = wr_single_seq::type_id::create($sformatf("wp%0d", i));
            rd_single_seq r = rd_single_seq::type_id::create($sformatf("rp%0d", i));
            w.s_addr = 40 + i;  w.s_data = pats[i];
            r.s_addr = 40 + i;
            w.start(env.wr_ag.sqr);
            r.start(env.rd_ag.sqr);
        end

        // 4. same-edge read/write collision
        col.start(env.vseqr);

        // 5. full-rate writes and reads in parallel
        conc.start(env.vseqr);

        // 6. random traffic
        repeat (10) begin
            dpram_random_vseq rnd = dpram_random_vseq::type_id::create("rnd");
            rnd.start(env.vseqr);
        end

        // 7. reset while a write is attempted, then read the address back
        w10.s_addr = 10;  w10.s_data = 8'hEE;
        r10.s_addr = 10;
        fork
            rst_vif.pulse(6);
            begin
                repeat (3) @(posedge rst_vif.clk);   // reset is already high
                w10.start(env.wr_ag.sqr);            // write attempted during reset
            end
        join
        r10.start(env.rd_ag.sqr);
    endtask
endclass
