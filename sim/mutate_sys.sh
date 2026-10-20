#!/bin/bash
# Mutation testing for the SYSTEM-level testbench: one bug at a time in top.v.
#   usage: bash mutate_sys.sh            all mutants in mutants_sys/*.sed
#          bash mutate_sys.sh S3 S6      only these
# Each mutant is first run with the real ROM (rom_data.mem is the identity ROM[i]=i).
# A survivor is run again with rom_scrambled.mem, because some bugs are invisible when
# the ROM data equals the address.

HERE=$(cd "$(dirname "$0")" && pwd)
ORIG="$HERE/../Design codes/top.v"
cd "$HERE" || exit 1

if [ $# -gt 0 ]; then
    mutants="$@"
else
    mutants=$(for f in mutants_sys/*.sed; do basename "$f" .sed; done)
fi

# run_one <mutant> <label> [extra make args]   -> prints the failing tests (empty = none)
run_one() {
    local m="$1" label="$2"; shift 2
    local dir="out/sysmut/$m/$label"
    make -s regress FILELIST=filelist_sys.f TOP=tb_top_sys REGRESS_LIST=regress_sys.list \
         OUT="$dir" TOPV="$HERE/out/sysmut/$m/top.v" "$@" > "$HERE/out/sysmut/$m/$label.txt" 2>&1
    if ! grep -q "^TEST " "$HERE/out/sysmut/$m/$label.txt"; then echo "BUILD-ERROR"; return; fi
    grep -E " +FAIL " "$HERE/out/sysmut/$m/$label.txt" | sed -E 's/ +FAIL .*//' | tr '\n' ';'
}

survivors=0
problems=0
printf "%-4s %-22s %s\n" MUT RESULT DETAIL

for m in $mutants; do
    mkdir -p "$HERE/out/sysmut/$m"
    sed -f "mutants_sys/$m.sed" "$ORIG" > "$HERE/out/sysmut/$m/top.v"

    if cmp -s "$ORIG" "$HERE/out/sysmut/$m/top.v"; then
        printf "%-4s %-22s %s\n" "$m" "NO-CHANGE" "sed pattern matched nothing"
        problems=$((problems + 1)); continue
    fi

    k=$(run_one "$m" idrom)
    if [ "$k" = "BUILD-ERROR" ]; then
        printf "%-4s %-22s %s\n" "$m" "BUILD-ERROR" "see out/sysmut/$m/idrom.txt"
        problems=$((problems + 1)); continue
    fi
    if [ -n "$k" ]; then
        printf "%-4s %-22s %s\n" "$m" "KILLED" "by: $k"
        continue
    fi

    # survived with the identity ROM: try the scrambled one
    k2=$(run_one "$m" scrambled ROM_MEM="$HERE/rom_scrambled.mem")
    if [ -n "$k2" ] && [ "$k2" != "BUILD-ERROR" ]; then
        printf "%-4s %-22s %s\n" "$m" "SURVIVED-IDENTITY-ROM" "but KILLED with scrambled ROM by: $k2"
    else
        printf "%-4s %-22s %s\n" "$m" "SURVIVED" "passed with both ROM files - a check is missing"
        survivors=$((survivors + 1))
    fi
done

echo "survivors: $survivors   problems: $problems"
exit $((survivors + problems))
