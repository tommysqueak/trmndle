#!/bin/sh
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/sandbox.sh"

new_sandbox

set_lipc_output com.lab126.powerd status <<'EOF'
Powerd state: Active
Remaining time in this state: 278.028561
defer_suspend:0
suspend_grace:0
prevent_screen_saver:0
drive_mode:off
Battery Level: 7%
Last batt event at: 7%
Charging: No
batt_full=0
Battery logging: On
EOF
cat > "$SB/response.json" <<'EOF'
{"image_url":"https:\/\/images.example\/p.png\u0026v=2","refresh_rate":"120","filename":"p.png"}
EOF
export STUB_CURL_BODY_FILE="$SB/response.json"

out=$(cd "$SB" && . ./config.sh && . ./utils.sh && . ./trmnl.sh && get_trmnl_image)

assert_eq "unescapes returned image_url" "https://images.example/p.png&v=2" "$out"
stub_called "png-width/screen-width is passed to api (landscape swap)" "png-width: 1024"
stub_called "png-height/screen-height is passed to api (landscape swap)" "png-height: 758"
stub_called "battery percent passed to api" "percent-charged: 7"
stub_called "access-token passed to api" "access-token: test-key"
stub_called "Device ID (mac address) passed to api" "ID: AA:BB:CC:DD:EE:FF"

drop_sandbox
summary
