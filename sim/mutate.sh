#!/bin/bash
# Mutation testing: inject one bug at a time into dpram.v and see if the regression catches it.
#   usage: bash mutate.sh            all mutants in mutants/*.sed
#          bash mutate.sh M2 M5      only these
# KILLED   = at least one test/assertion failed (good: the testbench sees the bug)
# SURVIVED = every test still passed (bad: a test or checker is missing)

HERE=$(cd "$(dirname "$0")" && pwd)
ORIG="$HERE/../Design codes/dpram.v"
cd "$HERE" || exit 1

if [ $# -gt 0 ]; then
    mutants="$@"
else
    mutants=$(for f in mutants/*.sed; do basename "$f" .sed; done)
fi

survivors=0
problems=0
printf "%-5s %-12s %s\n" MUT RESULT DETAIL

for m in $mutants; do
    dir="$HERE/out/mut/$m"
    rm -rf "$dir"
    mkdir -p "$dir"

    # 1. build the mutant from the original dpram.v
    sed -f "mutants/$m.sed" "$ORIG" > "$dir/dpram.v"

    # 2. a mutant identical to the original proves nothing
    if cmp -s "$ORIG" "$dir/dpram.v"; then
        printf "%-5s %-12s %s\n" "$m" "NO-CHANGE" "sed pattern matched nothing"
        problems=$((problems + 1))
        continue
    fi

    # 3. run the whole regression against the mutant (own build folder)
    make -s regress OUT="out/mut/$m" DUT="$dir/dpram.v" > "$dir/regress.txt" 2>&1

    # 4. no results table means the mutant did not even build: that is not a kill
    if ! grep -q "^TEST " "$dir/regress.txt"; then
        printf "%-5s %-12s %s\n" "$m" "BUILD-ERROR" "see out/mut/$m/regress.txt"
        problems=$((problems + 1))
        continue
    fi

    # 5. which tests failed?
    # rows look like:  <test> [(plusargs)]   FAIL  ...   ->  keep the label before FAIL
    killers=$(grep -E " +FAIL " "$dir/regress.txt" | sed -E 's/ +FAIL .*//' | tr '\n' ';')

    if [ -z "$killers" ]; then
        printf "%-5s %-12s %s\n" "$m" "SURVIVED" "all tests passed - a test is missing"
        survivors=$((survivors + 1))
    else
        printf "%-5s %-12s %s\n" "$m" "KILLED" "by: $killers"
    fi
done

echo "survivors: $survivors   problems: $problems"
exit $((survivors + problems))
