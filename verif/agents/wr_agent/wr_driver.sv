class wr_driver extends uvm_driver #(wr_item);
    `uvm_component_utils(wr_driver)
    virtual wr_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wr_if)::get(this, "", "wr_vif", vif))
            `uvm_fatal("NOVIF", "wr_vif not set for wr_driver")
    endfunction

    task run_phase(uvm_phase phase);
        // idle values
        vif.drv_cb.we         <= 0;
        vif.drv_cb.data       <= 0;
        vif.drv_cb.write_addr <= 0;

        // wait until reset is released
        wait (vif.rst === 0);

        // each loop iteration is one write_clock cycle
        forever begin
            // wait for the edge first, so the sequence has had a full clock to post
            // its next item; this allows true back-to-back writes
            @(vif.drv_cb);
            seq_item_port.try_next_item(req);
            if (req == null) begin
                // nothing to send: idle for one clock
                vif.drv_cb.we <= 0;
            end else begin
                vif.drv_cb.data       <= req.data;
                vif.drv_cb.write_addr <= req.write_addr;
                vif.drv_cb.we         <= req.we;
                seq_item_port.item_done();
            end
        end
    endtask
endclass
