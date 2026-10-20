class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    dpram_env      env;
    virtual rst_if rst_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = dpram_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", rst_vif))
            `uvm_fatal("NOVIF", "rst_vif not set for base_test")
    endfunction

    // tests override this task; the default is T01 (one write, one read)
    virtual task body();
        wr_single_seq wr_seq = wr_single_seq::type_id::create("wr_seq");
        rd_single_seq rd_seq = rd_single_seq::type_id::create("rd_seq");
        wr_seq.start(env.wr_ag.sqr);
        rd_seq.start(env.rd_ag.sqr);
    endtask

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "test is running", UVM_LOW)
        body();
        #100ns;     // let the last read reach the scoreboard
        phase.drop_objection(this);
    endtask
endclass
