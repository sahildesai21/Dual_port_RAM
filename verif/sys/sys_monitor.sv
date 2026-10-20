class sys_monitor extends uvm_monitor;
    `uvm_component_utils(sys_monitor)
    virtual sys_if vif;
    uvm_analysis_port #(sys_obs_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual sys_if)::get(this, "", "sys_vif", vif))
            `uvm_fatal("NOVIF", "sys_vif not set for sys_monitor")
    endfunction

    // publishes one observation per clock cycle
    task run_phase(uvm_phase phase);
        sys_obs_item item;
        int unsigned cycle = 0;
        forever begin
            @(vif.mon_cb);
            item = sys_obs_item::type_id::create("item");
            item.rst       = vif.mon_cb.rst;
            item.en        = vif.mon_cb.en;
            item.up_addr   = vif.mon_cb.up_addr;
            item.down_addr = vif.mon_cb.down_addr;
            item.rom_out   = vif.mon_cb.rom_out;
            item.ram_out   = vif.mon_cb.ram_out;
            item.sum_out   = vif.mon_cb.sum_out;
            item.cycle     = cycle++;
            ap.write(item);
        end
    endtask
endclass
