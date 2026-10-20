// one read; address can be set by the caller before start()
class rd_single_seq extends uvm_sequence #(rd_item);
    `uvm_object_utils(rd_single_seq)

    bit [5:0] s_addr = 3;

    function new(string name = "rd_single_seq"); super.new(name); endfunction

    task body();
        rd_item item = rd_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with { read_addr == s_addr; })
            `uvm_error("RAND", "randomize failed in rd_single_seq")
        finish_item(item);
    endtask
endclass

// read every address 0..63, one per clock
class rd_sweep_seq extends uvm_sequence #(rd_item);
    `uvm_object_utils(rd_sweep_seq)

    function new(string name = "rd_sweep_seq"); super.new(name); endfunction

    task body();
        for (int a = 0; a < 64; a++) begin
            rd_item   item = rd_item::type_id::create("item");
            bit [5:0] ad   = a[5:0];
            start_item(item);
            if (!item.randomize() with { read_addr == ad; })
                `uvm_error("RAND", "randomize failed in rd_sweep_seq")
            finish_item(item);
        end
    endtask
endclass

// random reads
class rd_rand_seq extends uvm_sequence #(rd_item);
    `uvm_object_utils(rd_rand_seq)

    rand int unsigned n;
    constraint c_n { n inside {[20:40]}; }

    function new(string name = "rd_rand_seq"); super.new(name); endfunction

    task body();
        repeat (n) begin
            rd_item item = rd_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("RAND", "randomize failed in rd_rand_seq")
            finish_item(item);
        end
    endtask
endclass
