// what the driver applies for one clock cycle
class sys_ctrl_item extends uvm_sequence_item;
    rand bit rst;
    rand bit en;

    `uvm_object_utils(sys_ctrl_item)

    function new(string name = "sys_ctrl_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("rst=%0b en=%0b", rst, en);
    endfunction
endclass

// what the monitor saw in one clock cycle (all values just before the clock edge)
class sys_obs_item extends uvm_sequence_item;
    logic       rst;
    logic       en;
    logic [7:0] up_addr;
    logic [7:0] down_addr;
    logic [7:0] rom_out;
    logic [7:0] ram_out;
    logic [7:0] sum_out;
    int unsigned cycle;

    `uvm_object_utils(sys_obs_item)

    function new(string name = "sys_obs_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("cycle=%0d rst=%0b en=%0b up=%0d down=%0d rom=0x%02h ram=0x%02h sum=0x%02h",
                         cycle, rst, en, up_addr, down_addr, rom_out, ram_out, sum_out);
    endfunction
endclass
