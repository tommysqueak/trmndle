#!/bin/sh
#
##############################################################################
#
# Read-only diagnostics for the onlinescreensaver extension.
#
# Usage: debug.sh [device|refresh|network|trmnl|files|logs|all]
#
##############################################################################

cd "$(dirname "$0")"

if [ -e "config.sh" ]; then
    . ./config.sh
fi
if [ -e "utils.sh" ]; then
    . ./utils.sh
fi

section () {
    printf '\n=== %s ===\n' "$1"
}

have () {
    type "$1" >/dev/null 2>&1
}

device_section () {
    section "device"
    if have eips; then
        eips -i
    else
        echo "eips not found"
    fi
    if have powerd_test; then
        powerd_test -s | grep "Battery Level"
    else
        echo "powerd_test not found"
    fi
    if have lipc-get-prop; then
        printf 'wifi cmState: %s\n' "$(lipc-get-prop com.lab126.wifid cmState)"
        if is_userstore_available; then
            echo "userstore: available"
        else
            echo "userstore: NOT available (USB mass storage active)"
        fi
    else
        echo "lipc-get-prop not found"
    fi
}

refresh_section () {
    section "refresh"
    if [ -f refresh_rate ]; then
        printf 'refresh_rate: %s seconds\n' "$(cat refresh_rate)"
    else
        echo "no refresh_rate stored yet (no successful update)"
    fi
    if [ ! -e "scheduler.sh" ]; then
        echo "scheduler.sh not found"
        return
    fi
    if ! have lipc-wait-event; then
        echo "lipc-wait-event not found"
        return
    fi
    # load scheduler.sh without entering its event loop
    TMPBIN=$(mktemp -d 2>/dev/null) || TMPBIN="/tmp/.debug-shims.$$"
    mkdir -p "$TMPBIN"
    printf '#!/bin/sh\nexit 0\n' > "$TMPBIN/lipc-wait-event"
    chmod +x "$TMPBIN/lipc-wait-event"
    OLDPATH=$PATH
    PATH="$TMPBIN:$PATH"
    export PATH
    NEXT_UPDATE=$(sh -c '
        . ./scheduler.sh
        get_next_update_seconds
    ')
    PATH=$OLDPATH
    rm -rf "$TMPBIN"
    printf 'next update in %s seconds\n' "$NEXT_UPDATE"
}

network_section () {
    section "network"
    if have lipc-get-prop; then
        printf 'wifi cmState: %s\n' "$(lipc-get-prop com.lab126.wifid cmState)"
    fi
    if ! have curl; then
        echo "curl not found"
        return
    fi
    for url in "$IMAGE_URI" "$TRMNL_BASE_URL"; do
        [ -n "$url" ] || continue
        if curl -fs -m 5 -o /dev/null "$url" 2>/dev/null; then
            echo "reachable:   $url"
        else
            echo "UNREACHABLE: $url"
        fi
    done
}

trmnl_section () {
    section "trmnl"
    if [ -z "$TRMNL_BASE_URL" ] || [ -z "$TRMNL_API_KEY" ]; then
        echo "TRMNL not configured (set TRMNL_BASE_URL and TRMNL_API_KEY in config.sh)"
        return
    fi
    if [ ! -e "trmnl.sh" ]; then
        echo "trmnl.sh not found"
        return
    fi
    . ./trmnl.sh
    printf 'panel dimensions: %s\n' "$(get_kindle_dimensions)"
    echo "dry run: same read-only API call an update makes (key not printed)"
    IMAGE_URL=$(get_trmnl_image)
    if [ -n "$IMAGE_URL" ]; then
        printf 'parsed image_url: %s\n' "$IMAGE_URL"
    else
        echo "no image_url parsed"
    fi
    if [ -f /tmp/onlinescreensaver_new.log ]; then
        echo "--- recent log lines ---"
        tail -n 5 /tmp/onlinescreensaver_new.log
    fi
}

files_section () {
    section "files"
    printf 'SCREENSAVERFILE: %s\n' "$SCREENSAVERFILE"
    if [ -f "$SCREENSAVERFILE" ]; then
        ls -l "$SCREENSAVERFILE"
    else
        echo "  missing"
    fi
    printf 'TMPFILE: %s\n' "$TMPFILE"
    if [ -f "$TMPFILE" ]; then
        ls -l "$TMPFILE"
    else
        echo "  absent"
    fi
    if [ -d "$SCREENSAVERFOLDER" ]; then
        echo "screensaver folder (newest first):"
        ls -lt "$SCREENSAVERFOLDER" 2>/dev/null | head -n 6
    fi
}

logs_section () {
    section "logs"
    printf 'LOGFILE: %s\n' "$LOGFILE"
    if [ -f "$LOGFILE" ]; then
        tail -n 30 "$LOGFILE"
    else
        echo "  no log file yet"
    fi
    if [ -f /tmp/onlinescreensaver_new.log ]; then
        echo "--- unflushed temp log ($(wc -c < /tmp/onlinescreensaver_new.log | tr -d ' ') bytes, last lines) ---"
        tail -n 10 /tmp/onlinescreensaver_new.log
    fi
}

case "${1:-all}" in
    device)   device_section ;;
    refresh)  refresh_section ;;
    network)  network_section ;;
    trmnl)    trmnl_section ;;
    files)    files_section ;;
    logs)     logs_section ;;
    all)      device_section
              refresh_section
              network_section
              trmnl_section
              files_section
              logs_section ;;
    *)        printf 'usage: %s [device|refresh|network|trmnl|files|logs|all]\n' "$0" >&2
              exit 2 ;;
esac
