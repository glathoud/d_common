#!/usr/bin/env bash

# Option: restricted test
TEST_PATTERN_IN="$1"
if [ "$TEST_PATTERN_IN" != "" ]; then
    TEST_PATTERN="$(basename ${TEST_PATTERN_IN})"
else
    TEST_PATTERN="*.d"
fi

# Option: number of parallel tasks (default: == number of CPU cores)
N_PAR_TASK="$2"
PAR_OPT=()
if [ "$N_PAR_TASK" != "" ]; then
    echo "N_PAR_TASK: ${N_PAR_TASK}"
    PAR_OPT=( -P "$N_PAR_TASK" )
fi

ME=$( realpath "$0" )
MY_DIR=$( dirname "$ME" )

cd "$MY_DIR"/..

function doit {
    echo
    echo ">>>>>>>>>> $1 <<<<<<<<<<"
    # rdmd --force -debug -g -gs -gf -gx -link-defaultlib-debug -inline -O --main -i -unittest $1
    # rdmd --force -debug -g -gs -gf -link-defaultlib-debug -inline -O --main -i -unittest $1
    rdmd --force -debug -g -gs -gf -link-defaultlib-debug --main -i -unittest $1
}
export -f doit

#find "${MY_DIR}" -name '*.d' | sort | xargs -n 1 grep -l unittest | xargs -n 1 bash -c 'doit "$@"' _

find "${MY_DIR}" -name "${TEST_PATTERN}" | sort | xargs -n 1 grep -l unittest | parallel --no-notice ${PAR_OPT[@]} doit "{}"
RESULT=$?

echo
echo "__________________________________________________"
echo
echo "Done: $(realpath $0)"
if [[ $RESULT == 0 ]]
then
    echo "=> Success!"
else
    echo "=> Failure! (result: $RESULT)"
fi
echo "__________________________________________________"
echo

exit $RESULT
