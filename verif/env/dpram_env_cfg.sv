class dpram_env_cfg extends uvm_object;
    `uvm_object_utils(dpram_env_cfg)

    bit has_scoreboard = 1;
    bit has_coverage   = 1;

    function new(string name = "dpram_env_cfg");
        super.new(name);
    endfunction
endclass
