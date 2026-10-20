class wr_monitor extends uvm_monitor;
    `uvm_component_utils(wr_monitor)
    virtual wr_if vif;
    uvm_analysis_port #(wr_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual wr_if)::get(this, "", "wr_vif", vif))
            `uvm_fatal("NOVIF", "wr_vif not set for wr_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        wr_item item;
        forever begin
            @(vif.mon_cb);
            // publish only writes that really happen (we=1 and rst=0)
            if (vif.mon_cb.rst == 0 && vif.mon_cb.we == 1) begin
                item = wr_item::type_id::create("item");
                item.data       = vif.mon_cb.data;
                item.write_addr = vif.mon_cb.write_addr;
                item.we         = vif.mon_cb.we;
                item.sample_time = $time;     // time of the clock edge this write was sampled at
                `uvm_info("WR_MON", item.convert2string(), UVM_LOW)
                ap.write(item);
            end
        end
    endtask
endclass
