# DPRAM Specification (DUT: `Design codes/dpram.v`)

Source of truth for this document is the current RTL. Where the RTL does not define a
behavior, it is listed under "Unspecified / open items" instead of being guessed.

## 1. Overview
A simple dual-port RAM: one write port and one read port, each with its own clock.
- Memory depth: 2^ADDR_WIDTH = 64 entries (default)
- Word width: DATA_WIDTH = 8 bits (default)
- Write port: synchronous to `write_clock`
- Read port: synchronous to `read_clock`, registered output

## 2. Parameters
| Name | Default | Meaning |
|---|---|---|
| DATA_WIDTH | 8 | Width of each memory word and of `data` / `q` |
| ADDR_WIDTH | 6 | Width of the address buses; depth = 2^ADDR_WIDTH (64) |

## 3. Ports
| Port | Dir | Width | Clock | Description |
|---|---|---|---|---|
| data | in | DATA_WIDTH | write_clock | Data to be written |
| write_addr | in | ADDR_WIDTH | write_clock | Write address |
| we | in | 1 | write_clock | Write enable, active high |
| write_clock | in | 1 | - | Write port clock (rising edge) |
| read_addr | in | ADDR_WIDTH | read_clock | Read address |
| read_clock | in | 1 | - | Read port clock (rising edge) |
| rst | in | 1 | both | Active-high synchronous reset (sampled on each clock) |
| q | out | DATA_WIDTH | read_clock | Registered read data |

## 4. Functional behavior

### 4.1 Write
On every rising edge of `write_clock`:
- `rst = 1`: no write occurs.
- `rst = 0` and `we = 1`: `ram[write_addr] <= data`.
- `rst = 0` and `we = 0`: memory unchanged.

### 4.2 Read
On every rising edge of `read_clock`:
- `rst = 1`: `q <= 0`.
- `rst = 0`: `q <= ram[read_addr]`.

Read latency is exactly 1 `read_clock` cycle: the address presented before edge N
appears on `q` after edge N. There is no read-enable; the port reads on every clock.

### 4.3 Reset
- Clears the output register `q` to 0 (on `read_clock`).
- Blocks writes while asserted (on `write_clock`).
- Does NOT clear memory contents. Data written before reset is still readable after it.

### 4.4 Initial state
- Simulation only: an `initial` block sets every memory location to 0.
- `q` has no initial value, so it is X until the first `read_clock` edge.

### 4.5 Same-address read and write
- Same clock, same address, same edge: the read returns the OLD value
  (non-blocking assignments). The new value is visible on the next read.
- Different clocks: the result is not defined by this spec (see section 6).

### 4.6 Attributes
- `(* ram_style = "block" *)` requests block-RAM inference in synthesis.

## 5. Expected timing (single clock, for the scoreboard)
| Cycle | Event |
|---|---|
| W | `we=1`, `write_addr=A`, `data=D` sampled at the write edge |
| W+1 onwards | `ram[A] = D` |
| R | `read_addr=A` sampled at the read edge |
| R (after edge) | `q = ram[A]` (value as of just before that edge) |

## 6. Unspecified / open items (to be decided, not assumed)
1. Same-address read/write on DIFFERENT clocks: old or new data? Plan: accept either, but flag X.
2. Behavior when inputs are X or Z: not defined.
3. `rst` is shared by both clock domains with no synchronizer. A real dual-clock design
   would need per-domain reset synchronization. Out of scope for verification now.
4. Reset asserted for only one edge of one clock when the clocks differ greatly in rate: not defined.

## 7. Out of scope (this document)
`top.v`, `rom.v`, counters, adder. They are covered in a later system-level phase, where the
intended behavior is "RAM[A] holds ROM[A]" (the current RTL stores ROM[A-1], a known skew).
