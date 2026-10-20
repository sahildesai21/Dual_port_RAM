// T16: reset in the middle of random traffic (reads and writes in flight when reset hits).
// The scoreboard must stay in sync: reads during reset return 0, writes during reset are
// ignored, memory contents survive, and every address still reads back correctly afterwards.
class reset_traffic_test extends base_test;
    `uvm_component_utils(reset_traffic_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        wr_sweep_seq      fill = wr_sweep_seq::type_id::create("fill");
        rd_sweep_seq      chk  = rd_sweep_seq::type_id::create("chk");
        dpram_random_vseq rnd  = dpram_random_vseq::type_id::create("rnd");

        // 1. known contents first
        fill.start(env.wr_ag.sqr);

        // 2. random traffic on both ports, with a reset pulse landing in the middle of it
        fork
            rnd.start(env.vseqr);
            begin
                repeat (12) @(posedge rst_vif.clk);   // let the traffic get going
                rst_vif.pulse(4);
            end
        join

        // 3. everything written outside reset must still be readable
        chk.start(env.rd_ag.sqr);
    endtask
endclass
