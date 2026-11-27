#!/bin/sh
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/sandbox.sh"

new_sandbox

out=$(cd "$SB" && export STUB_EIPS_XRES=600 STUB_EIPS_YRES=800 && . ./config.sh && . ./trmnl.sh && get_kindle_dimensions)
assert_eq "kindle dimensions" "600 800" "$out"

drop_sandbox
summary
