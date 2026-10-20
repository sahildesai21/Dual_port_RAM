class rd_monitor extends uvm_monitor;
    `uvm_component_utils(rd_monitor)
    virtual rd_if vif;
    
    uvm_analysis_port #(rd_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual rd_if)::get(this, "", "rd_vif", vif))
            `uvm_fatal("NOVIF", "rd_vif not set for rd_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        rd_item      item;
        logic [5:0]  prev_addr;
        bit          prev_rst;
        time         prev_time;
        bit          have_prev = 0;
        forever begin
            @(vif.mon_cb);
            if (have_prev) begin
                item = rd_item::type_id::create("item");
                item.read_addr = prev_addr;
                item.rst       = prev_rst;
                item.sample_time = prev_time;     // edge where read_addr was sampled
                item.q         = vif.mon_cb.q;    // result of the previous edge
                `uvm_info("RD_MON", item.convert2string(), UVM_LOW)
                ap.write(item);
            end
            prev_addr = vif.mon_cb.read_addr;
            prev_rst  = vif.mon_cb.rst;
            prev_time = $time;
            have_prev = 1;
        end
    endtask
endclass