// T09: full-rate writes and reads running in parallel
class back_to_back_test extends base_test;
    `uvm_component_utils(back_to_back_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        dpram_concurrent_vseq vseq = dpram_concurrent_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
    endtask
endclass
