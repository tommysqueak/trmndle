#!/bin/sh
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/sandbox.sh"

new_sandbox

run_case () {
    got=$( cd "$SB" && FAKE_CLOCK="$2" FAKE_EPOCH="$3" PASS_SCHED="$4" sh -c '
        . ./config.sh
        . ./utils.sh
        . ./scheduler.sh
        SCHEDULE="$PASS_SCHED"
        export SCHEDULE
        get_seconds_until_next_update
    ' )
    assert_eq "$1" "$5" "$got"
}

DEFAULT_SCHED="00:00-07:00=30 07:00-23:00=8 23:00-24:00=30"

run_case "mid-period interval boundary" "07:00:30" "1000000" "$DEFAULT_SCHED" 450
run_case "wait below 5 minutes raised to 300" "07:05:00" "1000000" "$DEFAULT_SCHED" 300
run_case "interval past period end clamps to end" "22:55:00" "1000000" "$DEFAULT_SCHED" 300
run_case "late-night period interval math" "23:45:00" "1000000" "$DEFAULT_SCHED" 900
run_case "gap between periods uses next period start" "07:00:00" "1000000" "00:00-06:00=30 09:00-10:00=15" 7200
run_case "day wrap to tomorrow's first period" "23:50:00" "1000000" "00:00-06:00=30" 600
run_case "exactly at period start" "00:00:00" "1000000" "00:00-06:00=30" 1800

drop_sandbox
summary
