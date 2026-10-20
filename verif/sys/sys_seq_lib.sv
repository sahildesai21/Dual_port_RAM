// hold reset for n cycles (en driven to en_during while in reset)
class sys_rst_seq extends uvm_sequence #(sys_ctrl_item);
    `uvm_object_utils(sys_rst_seq)

    int unsigned n         = 3;
    bit          en_during = 0;

    function new(string name = "sys_rst_seq"); super.new(name); endfunction

    task body();
        repeat (n) begin
            sys_ctrl_item item = sys_ctrl_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { rst == 1; en == en_during; })
                `uvm_error("RAND", "randomize failed in sys_rst_seq")
            finish_item(item);
        end
    endtask
endclass

// run for n cycles out of reset; en is high p_en percent of the time
class sys_run_seq extends uvm_sequence #(sys_ctrl_item);
    `uvm_object_utils(sys_run_seq)

    int unsigned n    = 300;
    int unsigned p_en = 100;

    function new(string name = "sys_run_seq"); super.new(name); endfunction

    task body();
        repeat (n) begin
            sys_ctrl_item item = sys_ctrl_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { rst == 0; en dist {1 := p_en, 0 := (100 - p_en)}; })
                `uvm_error("RAND", "randomize failed in sys_run_seq")
            finish_item(item);
        end
    endtask
endclass
