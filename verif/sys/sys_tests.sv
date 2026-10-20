class sys_base_test extends uvm_test;
    `uvm_component_utils(sys_base_test)

    sys_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sys_env::type_id::create("env", this);
    endfunction

    // helpers so tests read like a script
    task do_reset(int unsigned n, bit en_during = 0);
        sys_rst_seq r = sys_rst_seq::type_id::create("r");
        r.n = n;  r.en_during = en_during;
        r.start(env.agent.sqr);
    endtask

    task do_run(int unsigned n, int unsigned p_en = 100);
        sys_run_seq g = sys_run_seq::type_id::create("g");
        g.n = n;  g.p_en = p_en;
        g.start(env.agent.sqr);
    endtask

    virtual task body();
    endtask

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        body();
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// reset, then free-running counters for more than two laps of the ROM (and ten of the RAM)
class sys_basic_test extends sys_base_test;
    `uvm_component_utils(sys_basic_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task body();
        do_reset(3);
        do_run(600, 100);
    endtask
endclass

// en toggles randomly (60% high): counters pause and resume, writes follow en
class sys_enable_test extends sys_base_test;
    `uvm_component_utils(sys_enable_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task body();
        do_reset(3);
        do_run(600, 60);
    endtask
endclass

// resets in the middle of operation, one of them with en=1 during reset
class sys_reset_test extends sys_base_test;
    `uvm_component_utils(sys_reset_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task body();
        do_reset(3);
        do_run(150, 100);
        do_reset(2, 1);
        do_run(300, 80);
        do_reset(1);
        do_run(100, 100);
    endtask
endclass
