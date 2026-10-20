#!/bin/bash
# Run every line of the regress list on the already-built snapshot (use: make regress)
# A line is:  <uvm test> [NAME=value ...]   where each NAME=value is passed to xsim as a
# plusarg (for example WR_HALF=7.5 RD_HALF=5 to change the clocks). "#" starts a comment.
# A run PASSES only if: it really ran, the scoreboard checked reads, and there are
# no UVM_ERROR/UVM_FATAL lines and no assertion "Error:" lines.
# OUT (relative to sim/) selects the build folder (default out);
# REGRESS_LIST selects the list file (default regress.list).

HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${OUT:-out}
LIST=${REGRESS_LIST:-regress.list}

source /opt/Xilinx/2025.2/Vivado/settings64.sh > /dev/null 2>&1
cd "$HERE/$OUT" || exit 1

fails=0
printf "%-44s %-6s %s\n" "TEST (plusargs)" RESULT DETAIL

while read -r line; do
    line=${line%%#*}                 # strip comments
    set -- $line                     # split into words
    [ $# -eq 0 ] && continue
    t=$1
    shift
    args=("$@")

    plus=()
    for a in "${args[@]}"; do plus+=(-testplusarg "$a"); done

    label="$t"
    [ ${#args[@]} -gt 0 ] && label="$t (${args[*]})"
    tag=$(echo "$label" | tr -c 'A-Za-z0-9_.\n' '_')
    log="run_$tag.log"

    # timeout: a broken (mutated) DUT must not be able to hang the regression
    timeout 600 xsim --nolog tb_snap -R -testplusarg UVM_TESTNAME="$t" "${plus[@]}" > "$log" 2>&1
    # do not leave xsim journal/backup/waveform files behind (the console log is kept)
    rm -f xsim.jou xsim_*.backup.* tr_db.log ./*.wdb

    uvm_errs=$(grep -E "^UVM_(ERROR|FATAL) :" "$log" | awk '{s+=$3} END{print s+0}')
    sva_errs=$(grep -c "^Error:" "$log")
    ran=$(grep -cF "Running test $t..." "$log")
    sb=$(grep -oE "\[SB\] checked=[0-9]+ errors=[0-9]+" "$log" | head -1)
    cov=$(grep -oE "\[COV\] .*" "$log" | head -1)

    if [ "$uvm_errs" -eq 0 ] && [ "$sva_errs" -eq 0 ] && [ "$ran" -ge 1 ] && [ -n "$sb" ]; then
        result=PASS
    else
        result=FAIL
        fails=$((fails + 1))
    fi

    printf "%-44s %-6s %s | %s | uvm_err=%s sva_err=%s\n" "$label" "$result" "$sb" "$cov" "$uvm_errs" "$sva_errs"
done < "$HERE/$LIST"

echo "failures: $fails"
exit $fails
