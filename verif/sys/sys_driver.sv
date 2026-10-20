class sys_driver extends uvm_driver #(sys_ctrl_item);
    `uvm_component_utils(sys_driver)
    virtual sys_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sys_if)::get(this, "", "sys_vif", vif))
            `uvm_fatal("NOVIF", "sys_vif not set for sys_driver")
    endfunction

    // one item per clock: applied 1ns after an edge, sampled by the DUT at the next edge.
    // (tb_top_sys holds rst=1, en=0 from time 0 until the first item arrives.)
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            @(vif.drv_cb);
            vif.drv_cb.rst <= req.rst;
            vif.drv_cb.en  <= req.en;
            seq_item_port.item_done();
        end
    endtask
endclass
