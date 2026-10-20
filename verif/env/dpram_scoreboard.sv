`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class dpram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dpram_scoreboard)

    uvm_analysis_imp_wr #(wr_item, dpram_scoreboard) wr_imp;
    uvm_analysis_imp_rd #(rd_item, dpram_scoreboard) rd_imp;

    bit [7:0] model [bit [5:0]];   // reference memory: addr -> data
    wr_item   wr_q[$];             // writes seen but not yet applied to the model
    int       n_checked;
    int       n_errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wr_imp = new("wr_imp", this);
        rd_imp = new("rd_imp", this);
    endfunction

    // called by the write monitor: just remember the write, it is applied later
    function void write_wr(wr_item t);
        wr_q.push_back(t);
    endfunction

    // called by the read monitor (one clock after the read edge)
    function void write_rd(rd_item t);
        bit [7:0] expected;
        wr_item   w;

        // apply only writes that happened BEFORE this read edge. A write at the same
        // edge has not taken effect yet, so the read must still see the old value.
        while (wr_q.size() > 0 && wr_q[0].sample_time < t.sample_time) begin
            w = wr_q.pop_front();
            model[w.write_addr] = w.data;
        end

        // expected value of q after that read edge
        if (t.rst)
            expected = 8'h00;                 // reset clears q (not the memory)
        else if (^t.read_addr === 1'bx) begin
            `uvm_warning("SB", $sformatf("read_addr is X at %0t, not checked", t.sample_time))
            return;
        end
        else if (model.exists(t.read_addr))
            expected = model[t.read_addr];
        else
            expected = 8'h00;                 // never written: memory starts at 0

        n_checked++;
        if (t.q !== expected) begin
            n_errors++;
            `uvm_error("SB", $sformatf("MISMATCH @%0t addr=%0d rst=%0b expected=0x%02h got=0x%02h",
                                       t.sample_time, t.read_addr, t.rst, expected, t.q))
        end
        else
            `uvm_info("SB", $sformatf("match @%0t addr=%0d q=0x%02h", t.sample_time, t.read_addr, t.q), UVM_HIGH)
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (n_checked == 0)
            `uvm_error("SB", "scoreboard checked nothing - no reads were compared")
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB", $sformatf("checked=%0d errors=%0d", n_checked, n_errors), UVM_LOW)
    endfunction
endclass
