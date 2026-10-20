# DPRAM UVM simulation flow (Vivado xsim, run inside WSL)
#
# Usage (from the sim/ folder):
#   make                      compile + elaborate + run base_test        (dpram block level)
#   make TEST=my_test         run a different UVM test
#   make compile | elab | run run just one step (each step runs the ones before it)
#   make regress              run every line of regress.list, print a pass/fail table
#   make wave                 open the waveform in GTKWave
#   make clean                delete all generated files (sim/out)
#
# System level (top.v = counters + ROM + DPRAM + adder), results in sim/out/sys:
#   make sys                  run one system test   (SYS_TEST=sys_basic_test by default)
#   make sys_regress          run every line of regress_sys.list
#
# Options (used by mutate.sh and the sys targets, handy by hand too):
#   make OUT=out/foo ...      put all generated files in sim/out/foo instead of sim/out
#   make DUT=/abs/dpram.v ... simulate that file instead of "Design codes/dpram.v"
#   make FILELIST=f.f TOP=m   use another file list / top module
#   make TOPV=/abs/top.v      simulate that file instead of "Design codes/top.v" (system level)
#   make ROM_MEM=/abs/x.mem   use another ROM contents file (copied to the sim folder)
#
# All generated files (xsim.dir, logs, dpram.vcd) go into sim/out,
# so the source folders stay clean.

VIVADO_SETTINGS ?= /opt/Xilinx/2025.2/Vivado/settings64.sh
TEST            ?= base_test
SYS_TEST        ?= sys_basic_test
OUT             ?= out
DUT             ?=
FILELIST        ?= filelist.f
TOP             ?= tb_top
REGRESS_LIST    ?= regress.list
export OUT
export REGRESS_LIST

# absolute path of Dual_port_RAM/, so nested OUT folders work
ROOT := $(abspath $(CURDIR)/..)

TOPV            ?=
ROM_MEM         ?= $(ROOT)/Design codes/rom_data.mem

# include directories for the `include lines inside the packages
INCS := -i $(ROOT)/verif/tests \
        -i $(ROOT)/verif/agents/wr_agent \
        -i $(ROOT)/verif/agents/rd_agent \
        -i $(ROOT)/verif/env \
        -i $(ROOT)/verif/sequences \
        -i $(ROOT)/verif/sys

# use ">" instead of a TAB in front of recipe lines
.RECIPEPREFIX = >
SHELL        := /bin/bash
.SHELLFLAGS  := -o pipefail -c

.PHONY: all compile elab run regress wave clean sys sys_regress sys_regress_all

all: run

$(OUT):
> mkdir -p $(OUT)

# xvlog: compile. File list paths are relative to Dual_port_RAM/, so they are rewritten
# with the absolute project path into $(OUT)/files.f first.
# rom.v reads "rom_data.mem" from the simulation folder, so it is copied there.
compile: | $(OUT)
> sed -E 's#^"?([^"]*)"?[[:space:]]*$$#"$(ROOT)/\1"#' $(FILELIST) | grep -v '^"$(ROOT)/"$$' > $(OUT)/files.f
ifneq ($(DUT),)
> sed -i 's#"$(ROOT)/Design codes/dpram.v"#"$(DUT)"#' $(OUT)/files.f
endif
ifneq ($(TOPV),)
> sed -i 's#"$(ROOT)/Design codes/top.v"#"$(TOPV)"#' $(OUT)/files.f
endif
> cp "$(ROM_MEM)" $(OUT)/rom_data.mem
> source $(VIVADO_SETTINGS) > /dev/null 2>&1; cd $(OUT) && xvlog --nolog -sv -L uvm $(INCS) -f files.f

# xelab: build the simulation snapshot
elab: compile
> source $(VIVADO_SETTINGS) > /dev/null 2>&1; cd $(OUT) && xelab --nolog -L uvm $(TOP) -s tb_snap -timescale 1ns/1ps

# xsim: run the chosen UVM test, keep the log, then print the error counts.
# --nolog + the rm line keep xsim from leaving journal/backup/wdb files behind
# (the console output is already saved in run.log).
run: elab
> source $(VIVADO_SETTINGS) > /dev/null 2>&1; cd $(OUT) && xsim --nolog tb_snap -R -testplusarg UVM_TESTNAME=$(TEST) | tee run.log
> @rm -f $(OUT)/xsim.jou $(OUT)/xsim_*.backup.* $(OUT)/tr_db.log $(OUT)/*.wdb
> @echo "------ result for $(TEST) ------"
> @grep -E "^UVM_(WARNING|ERROR|FATAL) :" $(OUT)/run.log || true

# run every line of the regress list and print a pass/fail table
regress: elab
> bash ./regress.sh

# system level: same flow with the top.v file list and testbench
sys:
> $(MAKE) run FILELIST=filelist_sys.f TOP=tb_top_sys OUT=out/sys TEST=$(SYS_TEST)

sys_regress:
> $(MAKE) regress FILELIST=filelist_sys.f TOP=tb_top_sys OUT=out/sys REGRESS_LIST=regress_sys.list

# the same system tests, run a second time with a non-identity ROM (ROM[i] != i), because
# some bugs cannot be seen while the ROM data equals the address
sys_regress_all: sys_regress
> $(MAKE) regress FILELIST=filelist_sys.f TOP=tb_top_sys OUT=out/sys_rom2 REGRESS_LIST=regress_sys.list ROM_MEM=$(CURDIR)/rom_scrambled.mem

wave:
> cd $(OUT) && gtkwave dpram.vcd &

clean:
> rm -rf $(OUT)
