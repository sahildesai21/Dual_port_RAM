class rd_driver extends uvm_driver #(rd_item);
    `uvm_component_utils(rd_driver)
    virtual rd_if vif;
        function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rd_if)::get(this, "", "rd_vif", vif))
            `uvm_fatal("NOVIF", "rd_vif not set for rd_driver")
    endfunction

    task run_phase(uvm_phase phase);
        vif.drv_cb.read_addr <= 0;       // known value instead of X
        wait (vif.rst === 0);
        forever begin
            seq_item_port.get_next_item(req);   // blocks until a sequence sends one
            @(vif.drv_cb);
            vif.drv_cb.read_addr <= req.read_addr;
            seq_item_port.item_done();
        end
    endtask
endclass