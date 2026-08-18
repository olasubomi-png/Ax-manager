#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/thermal"
CONTROLLER="$ROOT_DIR/bin/thermal-controller"
WORK="${TMPDIR:-/tmp}/axgo-thermal-monitor.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$WORK"

OUTPUT="$(THERMAL_SYSFS_ROOT="$FIXTURE/normal" THERMAL_VIRTUAL_ROOT="$WORK/none" \
    THERMAL_DATA_ROOT="$WORK/data" THERMAL_MONITOR_ONCE=true \
    sh "$CONTROLLER" monitor --interval 1)"
printf '%s\n' "$OUTPUT" | grep -q "Interval: 1s" && pass "monitor interval accepted" || fail "monitor interval accepted"
printf '%s\n' "$OUTPUT" | grep -q "State: NORMAL" && pass "monitor reports state" || fail "monitor reports state"
printf '%s\n' "$OUTPUT" | grep -q "Throttle: NOT DETECTED" && pass "monitor reports throttle state" || fail "monitor reports throttle state"

if THERMAL_SYSFS_ROOT="$FIXTURE/normal" THERMAL_VIRTUAL_ROOT="$WORK/none" \
    THERMAL_DATA_ROOT="$WORK/data" sh "$CONTROLLER" monitor --interval malformed >/dev/null 2>&1; then
    fail "malformed monitor interval rejected"
else
    pass "malformed monitor interval rejected"
fi

OUTPUT="$(THERMAL_SYSFS_ROOT="$FIXTURE/hot" THERMAL_VIRTUAL_ROOT="$WORK/none" \
    THERMAL_DATA_ROOT="$WORK/data" sh "$CONTROLLER" status)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal throttling:" && pass "throttle status section" || fail "throttle status section"
printf '%s\n' "$OUTPUT" | grep -q "DETECTED" && pass "active cooling detects throttle" || fail "active cooling detects throttle"

[ "$FAILURES" -eq 0 ] && { echo "All thermal monitor tests passed."; exit 0; }
echo "$FAILURES thermal monitor test(s) failed."
exit 1