#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/thermal"
CONTROLLER="$ROOT_DIR/bin/thermal-controller"
WORK="${TMPDIR:-/tmp}/axgo-thermal-controller.$$"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run() {
    THERMAL_SYSFS_ROOT="$1" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" \
    THERMAL_DATA_ROOT="$WORK/data" sh "$CONTROLLER" "$2"
}

mkdir -p "$WORK"
OUTPUT="$(run "$FIXTURE/normal" status)"
printf '%s\n' "$OUTPUT" | grep -q "AX-T615 THERMAL STATUS" && pass "status command" || fail "status command"
printf '%s\n' "$OUTPUT" | grep -q "42.5°C" && pass "millidegree Celsius conversion" || fail "millidegree Celsius conversion"
printf '%s\n' "$OUTPUT" | grep -q "NORMAL" && pass "normal status classification" || fail "normal status classification"

OUTPUT="$(run "$FIXTURE/unknown" status)"
printf '%s\n' "$OUTPUT" | grep -q "UNKNOWN" && pass "invalid temperature becomes unknown" || fail "invalid temperature becomes unknown"
OUTPUT="$(run "$WORK/missing" status)"
printf '%s\n' "$OUTPUT" | grep -q "UNKNOWN" && pass "missing thermal root becomes unknown" || fail "missing thermal root becomes unknown"

BEFORE="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
run "$FIXTURE/normal" inspect >/dev/null
AFTER="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
[ "$BEFORE" = "$AFTER" ] && pass "fixture thermal filesystem unchanged" || fail "fixture thermal filesystem unchanged"

[ "$FAILURES" -eq 0 ] && { echo "All thermal controller tests passed."; exit 0; }
echo "$FAILURES thermal controller test(s) failed."
exit 1