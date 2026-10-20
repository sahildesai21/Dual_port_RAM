// virtual sequencer: holds handles to both real sequencers so a virtual
// sequence can drive the write and read ports together
class dpram_vseqr extends uvm_sequencer;
    `uvm_component_utils(dpram_vseqr)

    wr_sequencer wr_sqr;
    rd_sequencer rd_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
