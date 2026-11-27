#!/bin/sh
cd "$(dirname "$0")/.." || exit 1
rc=0
for t in tests/*.test.sh; do
    printf '== %s\n' "$t"
    sh "$t" || rc=1
done
if [ "$rc" -eq 0 ]; then
    echo "ALL PASS"
else
    echo "FAILURES"
fi
exit "$rc"
