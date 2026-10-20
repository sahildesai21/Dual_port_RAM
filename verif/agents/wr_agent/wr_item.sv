class wr_item extends uvm_sequence_item;
    time sample_time;
    rand logic [7:0] data;
    rand logic [5:0] write_addr;
    rand bit         we;

    `uvm_object_utils(wr_item)

    function new(string name = "wr_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("we=%0b addr=%0d data=0x%02h", we, write_addr, data);
    endfunction
endclass