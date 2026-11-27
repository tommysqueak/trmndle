#!/bin/sh
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/sandbox.sh"

API_JSON='{"status":0,"image_url":"http:\/\/image.example\/img.png","filename":"screen-a0f848-1795105057","refresh_rate":900,"reset_firmware":false,"update_firmware":false,"firmware_url":null,"special_function":"sleep","maximum_compatibility":false,"image_url_timeout":30}'

run_update () {
    ( cd "$SB" && sh ./update.sh )
}

new_sandbox
printf 'PNGDATA-FOR-TEST' > "$SB/image_body"

# A: two-step flow while powerd reports Screen Saver state
set_lipc_output com.lab126.powerd status <<'EOF'
Powerd state: Screen Saver
Remaining time in this state: 63.000000
defer_suspend:0
suspend_grace:0
prevent_screen_saver:0
drive_mode:off
Battery Level: 85%
Last batt event at: 85%
Charging: No
batt_full=0
Battery logging: On
EOF
printf '%s' "$API_JSON" > "$SB/response.json"
export STUB_CURL_BODY_FILE="$SB/response.json"
export STUB_WGET_BODY_FILE="$SB/image_body"

run_update >/dev/null 2>&1

assert_contains "image written to SCREENSAVERFILE" "PNGDATA-FOR-TEST" "$(cat "$SB/screensavers/bg_ss00.png")"
if [ -f "$SB/tmp.png" ]; then fail "temp file removed after success"; else pass; fi
stub_count "trmnl image downloaded" "wget http://image.example/img.png" 1
stub_called "screen refreshed via eips" "eips -f -g $SB/screensavers/bg_ss00.png"
curl_line=$(grep -n "curl" "$STUB_LOG" | head -1 | cut -d: -f1)
wget_line=$(grep -n "wget" "$STUB_LOG" | head -1 | cut -d: -f1)
if [ -n "$curl_line" ] && [ -n "$wget_line" ] && [ "$curl_line" -lt "$wget_line" ]; then pass; else fail "api call precedes image download"; fi
drop_sandbox

# B: image still written when device is active (no screen refresh)
new_sandbox
printf 'PNGDATA-FOR-TEST' > "$SB/image_body"
printf '%s' "$API_JSON" > "$SB/response.json"
export STUB_CURL_BODY_FILE="$SB/response.json"
export STUB_WGET_BODY_FILE="$SB/image_body"

run_update >/dev/null 2>&1

assert_contains "image written while active" "PNGDATA-FOR-TEST" "$(cat "$SB/screensavers/bg_ss00.png")"
stub_count "no eips refresh while active" "eips -f -g" 0
drop_sandbox

# C: download failure keeps old image and logs the exit code
new_sandbox
printf 'OLDDATA' > "$SB/screensavers/bg_ss00.png"
printf '%s' "$API_JSON" > "$SB/response.json"
export STUB_CURL_BODY_FILE="$SB/response.json"
export STUB_WGET_MODE=fail
export STUB_WGET_CODE=4

run_update >/dev/null 2>&1

assert_contains "old image kept on wget failure" "OLDDATA" "$(cat "$SB/screensavers/bg_ss00.png")"
if [ -f "$SB/tmp.png" ]; then fail "incomplete temp file cleaned up"; else pass; fi
assert_contains "wget exit code logged" "wget failed with exit code 4" "$(cat "$SB/test.log")"
drop_sandbox

# D: empty API response - download attempted with empty url, old image kept
new_sandbox
printf 'OLDDATA' > "$SB/screensavers/bg_ss00.png"
export STUB_CURL_BODY=""

run_update >/dev/null 2>&1

assert_contains "old image kept on empty api response" "OLDDATA" "$(cat "$SB/screensavers/bg_ss00.png")"
stub_count "download attempted with empty url" "wget  ->" 1
drop_sandbox

# E: no IMAGE_URI configured - nothing downloaded
new_sandbox
write_config "IMAGE_URI="
out=$( ( cd "$SB" && sh -c '. ./update.sh' ) 2>/dev/null )
stub_count "no downloads when IMAGE_URI unset" "wget" 0
drop_sandbox

summary
