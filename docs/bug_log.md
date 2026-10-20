# Bug log

DUT: `Design codes/dpram.v` (spec in `spec.md`, tests in `test_plan.md`).

## 1. Mutation results
Filled in from `bash sim/mutate.sh`. KILLED = a test or assertion failed. SURVIVED = nothing noticed,
which means a test is missing.

| Mutant | Bug injected | Result | Killed by (tests / assertion) | Action |
|---|---|---|---|---|
| M1 | write ignores `we` | KILLED | reset_test, random_test, full_test | Caught only by random/reset traffic: there is no directed `we=0` test (T05). Optional: add one so the kill is deterministic. |
| M2 | write happens during reset | KILLED | reset_test, full_test | None. Would have survived before TB-001 was fixed. |
| M3 | reset clears the memory contents | KILLED | reset_test, full_test | None. |
| M4 | `q` is combinational (not registered) | KILLED | all 7 tests | None. |
| M5 | address 63 is not writable | KILLED | write_read_test, back_to_back_test, reset_test, random_test, full_test | None. |
| M6 | same-edge collision returns the new data | KILLED | write_read_test, back_to_back_test, collision_test, reset_test, random_test, full_test | None. `collision_test` is the targeted one. |
| M7 | reset does not clear `q` | KILLED | all 7 tests | None. |
| M8 | data bit 7 stuck at 0 | KILLED | base_test, write_read_test, random_test, full_test | None. back_to_back_test misses it because the sweep data (0x40 or addr) never has bit 7 set. |

Result: 8 of 8 mutants killed, 0 survivors (first table: 7-test regression).
Full re-run on the final testbench (12-run regression incl. T14/T16 and the different-clock runs), `bash sim/mutate.sh`:
all 8 still KILLED, 0 survivors, 0 problems. Number of the 12 runs that caught each mutant:
M1: 8, M2: 6, M3: 6, M4: 12, M5: 10, M6: 11, M7: 12, M8: 9.
The assertions A1-A4 and A3b were also each proven to fire on a deliberately broken input
(using the real `verif/sva/dpram_assertions.sv`).

## 2. Real DUT bugs
| ID | Found by | Symptom | Root cause | Fix | Status |
|---|---|---|---|---|---|
| BUG-001 | system tests on `top.v` (`make sys_regress`): sys_basic_test, sys_enable_test, sys_reset_test, all FAIL | `RAM[A]` holds `ROM[A-1]` instead of `ROM[A]`. 1149 / 1109 / 1047 mismatches. First one: cycle 37, `ram_out` expected 0x00 got 0x1e; cycle 38: `ram_out` expected 0x1e (ROM[30]) got 0x1d (ROM[29]). | In `top.v` the write data is registered (`rom_out_reg`) and so is the write enable (`we_reg`), but the write address (`ram_wr_addr = up_addr[5:0]`) went straight to the DPRAM, so the data lands one address late. | New register `wr_addr_reg` in `top.v` (reset to 0, loaded with `ram_wr_addr` every clock) drives the DPRAM `write_addr`: 4 lines added, 1 changed. | FIXED and verified: sys_regress goes from 0 of 3 to 3 of 3 passing, 0 mismatches, 0 assertion errors; dpram regression unchanged (12 of 12). |

## 3. Testbench issues found
| ID | Found by | Symptom | Cause | Fix |
|---|---|---|---|---|
| TB-001 | coverage (`x=62.50`) | `reset_test` passed but never wrote while `rst=1`, so T07 was not really tested | the write started one clock edge before the reset pulse | start the write 3 clocks into a 6-clock reset (`reset_test.sv`, `full_test.sv`) |
| TB-002 | system-level mutation test (S6) | a `top.v` bug (`rom_out_reg <= up_addr` instead of the ROM data) passed all system tests | `rom_data.mem` is the identity ROM (`ROM[i] = i`), so wrong data equals right data | second system run with a non-identity ROM (`sim/rom_scrambled.mem`): `make sys_regress_all` |

## 4. System-level mutation results (`bash sim/mutate_sys.sh`, mutants of `top.v`)
Each mutant is run with the real ROM; a survivor is re-run with the scrambled ROM.

| Mutant | Bug injected into `top.v` | Result | Killed by |
|---|---|---|---|
| S1 | write enable always 1 (`we_reg <= 1'b1`) | KILLED | sys_enable_test, sys_reset_test |
| S2 | write address not registered (BUG-001 put back) | KILLED | all 3 system tests |
| S3 | adder uses `ram_out` instead of `ram_out_reg` | KILLED | all 3 system tests |
| S4 | adder uses `rom_out_reg` instead of `rom_out` | KILLED | all 3 system tests |
| S5 | RAM read address taken from the up counter | KILLED | all 3 system tests |
| S6 | `rom_out_reg` loads `up_addr` instead of the ROM data | SURVIVED with identity ROM, KILLED with scrambled ROM | all 3 system tests (scrambled ROM) |
| S7 | write address uses the wrong bit slice (`up_addr[6:1]`) | KILLED | all 3 system tests |
| S8 | reset does not clear `ram_out_reg` | KILLED | all 3 system tests |

Result: 8 of 8 killed, 0 survivors (S6 only with the scrambled ROM, see TB-002).
