// Cycle-accurate reference model of the INTENDED behaviour of top.v.
//
// Intended behaviour (the spec):
//   - up/down counters: reset to 0 / 0xFF, step only while en=1
//   - ROM data for the current up_addr is registered, together with its address and
//     the write enable (we = en), and written into RAM[address % 64] one cycle later,
//     so RAM[A % 64] ends up holding ROM[A]
//   - dpram: q <= old RAM[down_addr % 64] each clock (reset clears q, blocks writes)
//   - ram_out_reg is q delayed by one more clock; sum_out = rom_out + ram_out_reg
//
// Every observed cycle is compared with the model BEFORE the model is updated with that
// cycle's rst/en, so values are compared the way they look just before a clock edge.
class sys_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sys_scoreboard)

    uvm_analysis_imp #(sys_obs_item, sys_scoreboard) imp;

    logic [7:0] rom_m [0:255];     // ROM contents, read from the same rom_data.mem
    logic [7:0] mem   [0:63];      // model of the RAM contents

    logic [7:0] up_m, down_m;      // counters
    logic [7:0] rom_reg_m;         // rom_out_reg
    logic [5:0] addr_reg_m;        // registered write address
    bit         we_reg_m;          // we_reg
    logic [7:0] q_m;               // dpram q (= ram_out)
    logic [7:0] ram_out_reg_m;     // ram_out_reg

    bit         state_valid;       // model is defined after the first reset edge
    int         n_checked, n_errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
        foreach (rom_m[i]) rom_m[i] = 8'hxx;
        $readmemh("rom_data.mem", rom_m);          // file is in the simulation folder
        foreach (mem[i]) mem[i] = 8'h00;           // dpram starts at 0
    endfunction

    function void write(sys_obs_item t);
        if (state_valid) check_cycle(t);
        update_model(t);
    endfunction

    function void cmp(string name, sys_obs_item t, logic [7:0] got, logic [7:0] exp);
        if (got !== exp) begin
            n_errors++;
            if (n_errors <= 10)
                `uvm_error("SB", $sformatf("cycle %0d: %s expected 0x%02h got 0x%02h  (up=%0d down=%0d en=%0b rst=%0b)",
                                           t.cycle, name, exp, got, t.up_addr, t.down_addr, t.en, t.rst))
        end
    endfunction

    function void check_cycle(sys_obs_item t);
        logic [7:0] exp_rom = rom_m[up_m];
        logic [7:0] exp_sum = exp_rom + ram_out_reg_m;
        cmp("up_addr",   t, t.up_addr,   up_m);
        cmp("down_addr", t, t.down_addr, down_m);
        cmp("rom_out",   t, t.rom_out,   exp_rom);
        cmp("ram_out",   t, t.ram_out,   q_m);
        cmp("sum_out",   t, t.sum_out,   exp_sum);
        n_checked++;
    endfunction

    // what the DUT does at the clock edge that ends this cycle
    function void update_model(sys_obs_item t);
        logic [7:0] n_q, n_ram_out_reg, n_rom_reg, n_up, n_down;
        logic [5:0] n_addr;
        bit         n_we;

        if (t.rst === 1'b1) begin
            up_m = 8'h00;  down_m = 8'hFF;
            rom_reg_m = 8'h00;  ram_out_reg_m = 8'h00;
            we_reg_m = 0;  addr_reg_m = 6'd0;  q_m = 8'h00;
            state_valid = 1;                       // writes are blocked during reset
        end
        else if (state_valid) begin
            // next values, all computed from the current ones (like non-blocking assignments)
            n_q           = mem[down_m[5:0]];      // read sees the OLD memory value
            n_ram_out_reg = q_m;
            n_rom_reg     = rom_m[up_m];
            n_addr        = up_m[5:0];
            n_we          = (t.en === 1'b1);
            n_up          = (t.en === 1'b1) ? up_m   + 8'd1 : up_m;
            n_down        = (t.en === 1'b1) ? down_m - 8'd1 : down_m;

            if (we_reg_m) mem[addr_reg_m] = rom_reg_m;   // registered write lands now

            q_m = n_q;  ram_out_reg_m = n_ram_out_reg;  rom_reg_m = n_rom_reg;
            addr_reg_m = n_addr;  we_reg_m = n_we;  up_m = n_up;  down_m = n_down;
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (n_checked == 0)
            `uvm_error("SB", "scoreboard checked nothing - no cycles were compared")
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB", $sformatf("checked=%0d errors=%0d", n_checked, n_errors), UVM_LOW)
        if (n_errors > 10)
            `uvm_error("SB", $sformatf("%0d mismatches in total (only the first 10 were printed)", n_errors))
    endfunction
endclass
