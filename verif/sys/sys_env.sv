class sys_env extends uvm_env;
    `uvm_component_utils(sys_env)

    sys_agent      agent;
    sys_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = sys_agent::type_id::create("agent", this);
        sb    = sys_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.ap.connect(sb.imp);
    endfunction
endclass
