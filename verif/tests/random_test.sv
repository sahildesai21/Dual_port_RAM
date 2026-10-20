// T13 (also T05: some random writes have we=0): random traffic on both ports
class random_test extends base_test;
    `uvm_component_utils(random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        repeat (5) begin
            dpram_random_vseq vseq = dpram_random_vseq::type_id::create("vseq");
            vseq.start(env.vseqr);
        end
    endtask
endclass
