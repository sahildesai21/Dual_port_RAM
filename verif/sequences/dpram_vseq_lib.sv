class dpram_base_vseq extends uvm_sequence;
    `uvm_object_utils(dpram_base_vseq)
    `uvm_declare_p_sequencer(dpram_vseqr)

    function new(string name = "dpram_base_vseq"); super.new(name); endfunction
endclass

// T10: write a new value and read the same address at the same clock edge.
// The read must return the OLD value; the next read must return the new one.
class dpram_collision_vseq extends dpram_base_vseq;
    `uvm_object_utils(dpram_collision_vseq)

    function new(string name = "dpram_collision_vseq"); super.new(name); endfunction

    task body();
        wr_single_seq w_old = wr_single_seq::type_id::create("w_old");
        wr_single_seq w_new = wr_single_seq::type_id::create("w_new");
        rd_single_seq r1    = rd_single_seq::type_id::create("r1");
        rd_single_seq r2    = rd_single_seq::type_id::create("r2");

        w_old.s_addr = 20;  w_old.s_data = 8'h11;
        w_new.s_addr = 20;  w_new.s_data = 8'h22;
        r1.s_addr    = 20;
        r2.s_addr    = 20;

        w_old.start(p_sequencer.wr_sqr);        // RAM[20] = 0x11
        fork
            w_new.start(p_sequencer.wr_sqr);    // write 0x22 ...
            r1.start(p_sequencer.rd_sqr);       // ... while reading address 20
        join
        r2.start(p_sequencer.rd_sqr);           // now expect 0x22
    endtask
endclass

// T09: full-rate writes and reads running in parallel
class dpram_concurrent_vseq extends dpram_base_vseq;
    `uvm_object_utils(dpram_concurrent_vseq)

    function new(string name = "dpram_concurrent_vseq"); super.new(name); endfunction

    task body();
        wr_sweep_seq w = wr_sweep_seq::type_id::create("w");
        rd_sweep_seq r = rd_sweep_seq::type_id::create("r");
        fork
            w.start(p_sequencer.wr_sqr);
            r.start(p_sequencer.rd_sqr);
        join
    endtask
endclass

// T13: random writes and random reads running in parallel
class dpram_random_vseq extends dpram_base_vseq;
    `uvm_object_utils(dpram_random_vseq)

    function new(string name = "dpram_random_vseq"); super.new(name); endfunction

    task body();
        wr_rand_seq w = wr_rand_seq::type_id::create("w");
        rd_rand_seq r = rd_rand_seq::type_id::create("r");
        if (!w.randomize()) `uvm_error("RAND", "randomize failed for wr_rand_seq")
        if (!r.randomize()) `uvm_error("RAND", "randomize failed for rd_rand_seq")
        fork
            w.start(p_sequencer.wr_sqr);
            r.start(p_sequencer.rd_sqr);
        join
    endtask
endclass
