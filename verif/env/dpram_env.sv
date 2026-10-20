class dpram_env extends uvm_env;
    `uvm_component_utils(dpram_env)

    dpram_env_cfg    cfg;
    wr_agent         wr_ag;
    rd_agent         rd_ag;
    dpram_scoreboard sb;
    dpram_vseqr      vseqr;
    dpram_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // use the cfg a test provides, otherwise a default one
        if (!uvm_config_db#(dpram_env_cfg)::get(this, "", "cfg", cfg))
            cfg = dpram_env_cfg::type_id::create("cfg");

        wr_ag = wr_agent::type_id::create("wr_ag", this);
        rd_ag = rd_agent::type_id::create("rd_ag", this);
        vseqr = dpram_vseqr::type_id::create("vseqr", this);
        if (cfg.has_scoreboard)
            sb = dpram_scoreboard::type_id::create("sb", this);
        if (cfg.has_coverage)
            cov = dpram_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vseqr.wr_sqr = wr_ag.sqr;
        vseqr.rd_sqr = rd_ag.sqr;
        if (cfg.has_scoreboard) begin
            wr_ag.mon.ap.connect(sb.wr_imp);
            rd_ag.mon.ap.connect(sb.rd_imp);
        end
    endfunction
endclass
