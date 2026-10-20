// T10: read and write of the same address at the same edge (read must see old data)
class collision_test extends base_test;
    `uvm_component_utils(collision_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task body();
        dpram_collision_vseq vseq = dpram_collision_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
    endtask
endclass
