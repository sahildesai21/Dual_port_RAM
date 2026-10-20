class rd_item extends uvm_sequence_item;
    rand logic [5:0] read_addr;
         logic [7:0] q;       // filled in by the monitor
         bit         rst;     // reset was active when read_addr was sampled
         time        sample_time;  // time of the clock edge read_addr was sampled at

    `uvm_object_utils(rd_item)

    function new(string name = "rd_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("rst=%0b addr=%0d q=0x%02h", rst, read_addr, q);
    endfunction
endclass