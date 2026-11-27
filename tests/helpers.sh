# Minimal POSIX test helpers. Source from t_*.sh scripts.

PASS_COUNT=0
FAIL_COUNT=0

pass () {
    PASS_COUNT=$(( PASS_COUNT + 1 ))
}

fail () {
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
    printf 'FAIL: %s\n' "$1"
    if [ $# -ge 3 ]; then
        printf '  want: %s\n  got:  %s\n' "$2" "$3"
    fi
}

assert_eq () {
    if [ "$2" = "$3" ]; then pass; else fail "$1" "$2" "$3"; fi
}

assert_contains () {
    case "$3" in
        *"$2"*) pass ;;
        *) fail "$1" "$2" "$3" ;;
    esac
}

assert_file () {
    if [ -f "$2" ]; then pass; else fail "$1" "file exists" "$2"; fi
}

stub_called () {
    if grep -qF -- "$2" "$STUB_LOG" 2>/dev/null; then pass; else fail "$1" "$2" "(not found in stub log)"; fi
}

stub_count () {
    n=$(grep -cF -- "$2" "$STUB_LOG" 2>/dev/null)
    assert_eq "$1" "$3" "${n:-0}"
}

summary () {
    printf '%s: %d passed, %d failed\n' "$0" "$PASS_COUNT" "$FAIL_COUNT"
    [ "$FAIL_COUNT" -eq 0 ]
}
