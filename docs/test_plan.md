# DPRAM Verification Test Plan

DUT: `dpram.v` (spec in `spec.md`).  Environment: UVM 1.2 on Vivado xsim, waves in GTKWave.

## 1. Verification approach
- Two agents: `wr_agent` drives the write port, `rd_agent` drives the read port.
- The scoreboard keeps a reference model (associative array `addr -> data`) updated from the
  write monitor. On every read it predicts `q` (1 read clock later) and compares with the DUT.
- Coverage is collected on addresses, data, `we`, reset and collisions.
- SVA is bound to the DUT for the rules in section 4.

## 2. Reference model rules (scoreboard)
1. A write is recorded when `we=1` and `rst=0` at a write edge.
2. Reset clears the predicted `q` to 0 but NOT the stored contents.
3. Unwritten locations read as 0 (simulation init).
4. Predicted `q` at read edge N = model[read_addr at edge N], taken before any write at the same edge.
5. Reads before the first read edge are not compared (`q` is X).

## 3. Test list
Priority: P1 = must, P2 = should, P3 = nice to have. File = UVM test class to create.

| ID | Test (file) | Objective | Stimulus | Pass criterion | Pri |
|---|---|---|---|---|---|
| T01 | single_wr_rd (write_read_test) | Basic store and fetch | Write 0xA5 to addr 3, read addr 3 | q == 0xA5 | P1 |
| T02 | full_sweep (write_read_test) | Every location works | Write unique data to all 64 addrs, read all back | All 64 match model | P1 |
| T03 | read_latency | Latency is exactly 1 read clock | Change read_addr each cycle on pre-filled RAM | q follows addr delayed by exactly 1 cycle | P1 |
| T04 | overwrite | Later write replaces earlier | Write D1 then D2 to same addr, read | q == D2 | P1 |
| T05 | we_low | we=0 never writes | Drive data/addr with we=0, then read | Memory unchanged | P1 |
| T06 | reset_q | Reset clears q | Read a nonzero location, assert rst | q == 0 while/after rst | P1 |
| T07 | reset_blocks_write | Writes ignored during rst | we=1 while rst=1, then release and read | Location not updated | P1 |
| T08 | reset_keeps_data | Reset does not clear memory | Fill, reset, read back | Old data still read | P1 |
| T09 | back_to_back (back_to_back_test) | Full throughput | Write every cycle with changing addr, read every cycle | No lost or duplicated data | P1 |
| T10 | collision_same_clk (collision_test) | Read-during-write | Same addr, same edge, same clock | q returns OLD value, next read returns new | P1 |
| T11 | boundary | Edge addresses | Write/read addr 0 and 63 | Match model | P2 |
| T12 | data_patterns | Bit-level integrity | 0x00, 0xFF, 0xAA, 0x55, walking 1, walking 0 | Match model | P2 |
| T13 | random_mix | Broad coverage | Constrained-random wr/rd addr, data, we | Scoreboard clean, coverage closes | P1 |
| T14 | diff_clocks | Dual-clock operation | write_clock != read_clock (e.g. 100/66 MHz, and the reverse) | Reads see written data; no X | P2 |
| T15 | collision_diff_clk | Cross-domain collision | Same addr, different clocks | q is old OR new, never X (open item 6.1) | P3 |
| T16 | reset_mid_traffic (reset_test) | Reset in the middle of activity | Assert rst during random traffic | Scoreboard stays in sync; T06-T08 rules hold | P2 |
| T17 | idle_hold | No spurious change | No writes, constant read_addr for many cycles | q stable | P3 |

## 4. Assertions (SVA, `verif/sva/dpram_assertions.sv`)
| ID | Rule |
|---|---|
| A1 | After a read edge with rst=1, q == 0 |
| A2 | q is never X after the first read edge |
| A3 | With we=0 (or rst=1) at a write edge, no memory location changes (checked via model) |
| A4 | Read latency: q equals the value at read_addr sampled one read edge earlier |

## 5. Functional coverage (`dpram_coverage.sv`)
- write_addr: every address hit (64 bins) plus boundary bins
- read_addr: every address hit (64 bins)
- data: zero, all-ones, alternating, other
- we: 0 and 1, and transitions
- rst: asserted while idle, during write, during read
- cross: write_addr == read_addr (collision) vs different
- cross: we x rst

## 6. Mutation testing (prove the testbench catches bugs)
Make a copy of dpram.v per mutant, run the regression, and record which tests fail.

| ID | Mutant | Expected to be caught by |
|---|---|---|
| M1 | Write ignores `we` | T05 |
| M2 | Write happens during rst | T07 |
| M3 | Reset clears memory contents | T08 |
| M4 | Read has no register (combinational q) | T03, A4 |
| M5 | Last address (63) not writable | T02, T11 |
| M6 | Read returns NEW data on same-address collision | T10 |
| M7 | Reset does not clear q | T06, A1 |
| M8 | Data bit 7 stuck at 0 | T12 |

A mutant that no test fails on means a test or checker is missing.

## 7. Entry / exit criteria
- Entry: UVM env compiles; T01 passes on the unmodified DUT.
- Exit: all P1 and P2 tests pass; functional coverage is 100% on the items in section 5;
  all mutants M1-M8 are caught; every bug is logged in `bug_log.md`.

## 8. Suggested build order
T01 first (proves the env wiring), then T02-T09, then T10-T13, then T14-T17,
then SVA and coverage, then the mutants.
