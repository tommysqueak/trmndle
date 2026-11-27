#!/bin/sh
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/sandbox.sh"

new_sandbox

run_case () {
    got=$( cd "$SB" && sh -c '
        . ./config.sh
        . ./utils.sh
        . ./scheduler.sh
        get_next_update_seconds
    ' )
    assert_eq "$1" "$2" "$got"
}

printf '900\n' > "$SB/refresh_rate"
run_case "reads persisted refresh rate" "900"

rm -f "$SB/refresh_rate"
run_case "missing state file falls back to 300" "300"

printf 'abc\n' > "$SB/refresh_rate"
run_case "non-numeric state file falls back to 300" "300"

printf '\n' > "$SB/refresh_rate"
run_case "empty state file falls back to 300" "300"

printf '60\n' > "$SB/refresh_rate"
run_case "below-floor rate raised to 300" "300"

printf '999999\n' > "$SB/refresh_rate"
run_case "implausible 6-digit rate falls back to 300" "300"

drop_sandbox
summary
