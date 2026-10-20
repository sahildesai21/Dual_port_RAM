// one write; address and data can be set by the caller before start()
class wr_single_seq extends uvm_sequence #(wr_item);
    `uvm_object_utils(wr_single_seq)

    bit [5:0] s_addr = 3;
    bit [7:0] s_data = 8'hA5;

    function new(string name = "wr_single_seq"); super.new(name); endfunction

    task body();
        wr_item item = wr_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with { write_addr == s_addr; data == s_data; we == 1; })
            `uvm_error("RAND", "randomize failed in wr_single_seq")
        finish_item(item);
    endtask
endclass

// T02: write every address 0..63, data = 0x40 | addr (unique per address)
class wr_sweep_seq extends uvm_sequence #(wr_item);
    `uvm_object_utils(wr_sweep_seq)

    function new(string name = "wr_sweep_seq"); super.new(name); endfunction

    task body();
        for (int a = 0; a < 64; a++) begin
            wr_item   item = wr_item::type_id::create("item");
            bit [5:0] ad   = a[5:0];
            start_item(item);
            if (!item.randomize() with { write_addr == ad; data == (8'h40 | ad); we == 1; })
                `uvm_error("RAND", "randomize failed in wr_sweep_seq")
            finish_item(item);
        end
    endtask
endclass

// T13 / T05: random writes, about 20% of them with we=0
class wr_rand_seq extends uvm_sequence #(wr_item);
    `uvm_object_utils(wr_rand_seq)

    rand int unsigned n;
    constraint c_n { n inside {[20:40]}; }

    function new(string name = "wr_rand_seq"); super.new(name); endfunction

    task body();
        repeat (n) begin
            wr_item item = wr_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { we dist {1 := 80, 0 := 20}; })
                `uvm_error("RAND", "randomize failed in wr_rand_seq")
            finish_item(item);
        end
    endtask
endclass
