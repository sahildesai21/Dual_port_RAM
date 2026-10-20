class sys_sequencer extends uvm_sequencer #(sys_ctrl_item);
    `uvm_component_utils(sys_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

class sys_agent extends uvm_agent;
    `uvm_component_utils(sys_agent)
    sys_sequencer sqr;
    sys_driver    drv;
    sys_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = sys_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = sys_sequencer::type_id::create("sqr", this);
            drv = sys_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass
