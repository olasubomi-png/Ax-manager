#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/thermal"
CONTROLLER="$ROOT_DIR/bin/thermal-controller"
WORK="${TMPDIR:-/tmp}/axgo-thermal-detection.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
inspect() {
    THERMAL_SYSFS_ROOT="$FIXTURE/$1" THERMAL_VIRTUAL_ROOT="$WORK/none" \
    THERMAL_DATA_ROOT="$WORK/data" sh "$CONTROLLER" inspect
}
mkdir -p "$WORK"

OUTPUT="$(inspect normal)"
printf '%s\n' "$OUTPUT" | grep -q "Zones detected: 2" && pass "multiple thermal zones detected" || fail "multiple thermal zones detected"
printf '%s\n' "$OUTPUT" | grep -q "Trip 0" && pass "trip point discovered read-only" || fail "trip point discovered read-only"
printf '%s\n' "$OUTPUT" | grep -q "COOLING DEVICE" && pass "cooling device discovered" || fail "cooling device discovered"
printf '%s\n' "$OUTPUT" | grep -q "Current state: 0" && pass "cooling state reported" || fail "cooling state reported"

OUTPUT="$(inspect unknown)"
printf '%s\n' "$OUTPUT" | grep -q "Type: vendor-zone-unknown" && pass "unknown zone type is preserved" || fail "unknown zone type is preserved"
printf '%s\n' "$OUTPUT" | grep -q "Temperature: UNKNOWN°C" && pass "unknown zone temperature reported" || fail "unknown zone temperature reported"
printf '%s\n' "$OUTPUT" | grep -q "Throttle detection: UNKNOWN" && pass "malformed throttle data is unknown" || fail "malformed throttle data is unknown"

[ "$FAILURES" -eq 0 ] && { echo "All thermal detection tests passed."; exit 0; }
echo "$FAILURES thermal detection test(s) failed."
exit 1