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
# verbatim real API reply
cat > "$SB/response.json" <<'EOF'
{"status":0,"image_url":"http:\/\/trmnl.local\/storage\/images\/setup-logo.bmp","filename":"screen-a0f848-1795105057","refresh_rate":900,"reset_firmware":false,"update_firmware":false,"firmware_url":null,"special_function":"sleep","maximum_compatibility":false,"image_url_timeout":30}
EOF
export STUB_CURL_API_BODY_FILE="$SB/response.json"

out=$(cd "$SB" && . ./config.sh && . ./utils.sh && . ./trmnl.sh && get_trmnl_image)

assert_eq "parses real api reply image_url" "http://trmnl.local/storage/images/setup-logo.bmp" "$out"
stub_called "png-width/screen-width is passed to api (landscape swap)" "png-width: 1024"
stub_called "png-height/screen-height is passed to api (landscape swap)" "png-height: 758"
stub_called "battery percent passed to api" "percent-charged: 7"
stub_called "access-token passed to api" "access-token: test-key"
stub_called "Device ID (mac address) passed to api" "ID: AA:BB:CC:DD:EE:FF"

assert_eq "persists refresh_rate for scheduler" "900" "$(cat "$SB/refresh_rate" 2>/dev/null)"

# variant with query parameters, as sent for signed image urls
cat > "$SB/response.json" <<'EOF'
{"status":0,"image_url":"https:\/\/images.example\/p.png\u0026v=2","filename":"screen-x","refresh_rate":900,"special_function":"sleep"}
EOF

out=$(cd "$SB" && . ./config.sh && . ./utils.sh && . ./trmnl.sh && get_trmnl_image)
assert_eq "unescapes query parameters in image_url" "https://images.example/p.png&v=2" "$out"

# API may send a rate below the device floor; clamped value must be persisted
cat > "$SB/response.json" <<'EOF'
{"status":0,"image_url":"https:\/\/images.example\/p.png","filename":"screen-y","refresh_rate":60}
EOF

out=$(cd "$SB" && . ./config.sh && . ./utils.sh && . ./trmnl.sh && get_trmnl_image)
assert_eq "persists clamped below-floor refresh_rate" "300" "$(cat "$SB/refresh_rate" 2>/dev/null)"

drop_sandbox
summary
