// Functional coverage. Samples the interface signals on every edge of either clock.
// cp_col means "a write address equals the address currently on read_addr"; with aligned
// clocks that is the same-edge collision, with unaligned clocks it is a cross-domain overlap.
class dpram_coverage extends uvm_component;
    `uvm_component_utils(dpram_coverage)

    virtual wr_if wvif;
    virtual rd_if rvif;

    // values sampled each clock
    bit        we, rst;
    bit [5:0]  wa, ra;
    bit [7:0]  wd;

    covergroup cg;
        cp_wa:  coverpoint wa iff (we && !rst) { bins all[] = {[0:63]}; }   // every write address
        cp_ra:  coverpoint ra iff (!rst)       { bins all[] = {[0:63]}; }   // every read address
        cp_wd:  coverpoint wd iff (we && !rst) {
                    bins zero  = {8'h00};
                    bins ones  = {8'hFF};
                    bins alt   = {8'hAA, 8'h55};
                    bins other = default; }
        cp_we:  coverpoint we  { bins z = {0}; bins o = {1}; bins up = (0 => 1); bins dn = (1 => 0); }
        cp_rst: coverpoint rst;
        cx_we_rst: cross cp_we, cp_rst;                                     // reset during write / idle
        cp_col: coverpoint (we && !rst && (wa == ra)) { bins hit = {1}; }   // same-edge collision
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wr_if)::get(this, "", "wr_vif", wvif))
            `uvm_fatal("NOVIF", "wr_vif not set for dpram_coverage")
        if (!uvm_config_db#(virtual rd_if)::get(this, "", "rd_vif", rvif))
            `uvm_fatal("NOVIF", "rd_vif not set for dpram_coverage")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            // sample on an edge of EITHER clock, so unaligned read/write clocks (T14) are
            // covered too; with aligned clocks both edges coincide
            @(posedge wvif.write_clock or posedge rvif.read_clock);
            // the drivers change signals 1ns after an edge, so these are the values the DUT sees
            we  = wvif.we;
            rst = wvif.rst;
            wa  = wvif.write_addr;
            wd  = wvif.data;
            ra  = rvif.read_addr;
            cg.sample();
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", $sformatf("total=%0.2f%% wa=%0.2f ra=%0.2f wd=%0.2f we=%0.2f x=%0.2f col=%0.2f",
            cg.get_inst_coverage(), cg.cp_wa.get_inst_coverage(), cg.cp_ra.get_inst_coverage(),
            cg.cp_wd.get_inst_coverage(), cg.cp_we.get_inst_coverage(),
            cg.cx_we_rst.get_inst_coverage(), cg.cp_col.get_inst_coverage()), UVM_LOW)
    endfunction
endclass
