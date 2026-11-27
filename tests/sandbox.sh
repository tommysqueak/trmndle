# Per-test sandbox: copy bin/, generate config.sh, put stubs on PATH.
# Source after helpers.sh. Sets SB, STUB_LOG, STUB_LIPC.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUBS="$ROOT/tests/stubs/bin"

write_config () {
    cat > "$SB/config.sh" <<EOF
DEFAULTINTERVAL=5
SCHEDULE="00:00-07:00=30 07:00-23:00=8 23:00-24:00=30"
IMAGE_URI="http://image.example/img.png"
SCREENSAVERFOLDER="$SB/screensavers"
SCREENSAVERFILE="$SB/screensavers/bg_ss00.png"
LOGGING=1
LOGFILE="$SB/test.log"
TMPFILE="$SB/tmp.png"
TRMNL_BASE_URL="http://trmnl.example"
TRMNL_API_KEY="test-key"
$1
EOF
}

new_sandbox () {
    SB="$(mktemp -d "${TMPDIR:-/tmp}/onlinescreensaver-test.XXXXXX")"
    cp "$ROOT"/bin/*.sh "$SB/"
    mkdir -p "$SB/screensavers"
    write_config ""
    STUB_LOG="$SB/stubs.log"
    : > "$STUB_LOG"
    export STUB_LOG
    export STUB_WGET_MODE=ok
    export STUB_WGET_CODE=
    export STUB_WGET_BODY=
    export STUB_WGET_BODY_FILE=
    export STUB_CURL_BODY=
    export STUB_CURL_BODY_FILE=
    cp -R "$ROOT/tests/stubs/lipc" "$SB/lipc"
    STUB_LIPC="$SB/lipc"
    export STUB_LIPC
    rm -f /tmp/onlinescreensaver_new.log
    PATH="$STUBS:$PATH"
    export PATH
}

drop_sandbox () {
    [ -n "$SB" ] && rm -rf "$SB"
}

set_lipc_output () {
    cat > "$STUB_LIPC/$1__$2"
}
