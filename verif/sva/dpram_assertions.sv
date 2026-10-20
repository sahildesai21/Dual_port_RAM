// Assertions on the DPRAM pins. Bound into dpram without editing dpram.v (see bind at the end).
// Rules that need the memory contents (we=0 never writes, read latency) are checked by the
// scoreboard instead, because a bound checker cannot see the memory array.
module dpram_assertions #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 6)
(
    input logic                  read_clock,
    input logic                  write_clock,
    input logic                  rst,
    input logic                  we,
    input logic [DATA_WIDTH-1:0] data,
    input logic [DATA_WIDTH-1:0] q,
    input logic [ADDR_WIDTH-1:0] read_addr,
    input logic [ADDR_WIDTH-1:0] write_addr
);
    bit      seen_rd_edge;      // goes 1 after the first read clock edge
    realtime last_rd_edge;      // time of the latest read clock edge

    always @(posedge read_clock) begin
        seen_rd_edge <= 1;
        last_rd_edge  = $realtime;
    end

    // A1: a read edge with rst=1 must leave q == 0
    a1_rst_clears_q: assert property (@(posedge read_clock) rst |=> (q == '0))
        else $error("A1: q not cleared by reset");

    // A2: q is never X/Z after the first read edge
    a2_q_known: assert property (@(posedge read_clock) seen_rd_edge |-> !$isunknown(q))
        else $error("A2: q is X/Z after the first read edge");

    // A3: when we=1 outside reset, write_addr and data are known
    a3_wr_known: assert property (@(posedge write_clock) disable iff (rst) we |-> !$isunknown({write_addr, data}))
        else $error("A3: write address/data unknown while we=1");

    // A3b: we itself is never X/Z outside reset
    a3b_we_known: assert property (@(posedge write_clock) disable iff (rst) !$isunknown(we))
        else $error("A3b: we is X/Z outside reset");

    // A4: q is registered, so it may only change at a read clock edge
    always @(q) begin
        if (seen_rd_edge && ($realtime != last_rd_edge))
            $error("A4: q changed outside a read_clock edge");
    end
endmodule

bind dpram dpram_assertions #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_sva (.*);
