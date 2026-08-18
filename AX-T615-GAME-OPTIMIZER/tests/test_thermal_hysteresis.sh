#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
GUARD="$ROOT_DIR/bin/thermal-guard"
FIXTURE="$TEST_DIR/fixtures/thermal"
WORK="${TMPDIR:-/tmp}/axgo-thermal-hysteresis.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run() {
    FIX="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" THERMAL_DATA_ROOT="$WORK/data" \
    THERMAL_SYSFS_ROOT="$FIXTURE/$FIX" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" \
        sh "$GUARD" "$@"
}
mkdir -p "$WORK"
run caution game-start fluctuation >/dev/null
OUTPUT="$(run fluctuation recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "initial caution state is retained" || fail "initial caution state is retained"
OUTPUT="$(run normal recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "small fluctuation does not immediately recover" || fail "small fluctuation does not immediately recover"
OUTPUT="$(run recovery recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "recovery waits for stable samples" || fail "recovery waits for stable samples"
OUTPUT="$(run recovery recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: NORMAL" && pass "recovery completes after stable samples" || fail "recovery completes after stable samples"
run recovery game-stop >/dev/null
[ "$FAILURES" -eq 0 ] && { echo "All thermal hysteresis tests passed."; exit 0; }
echo "$FAILURES thermal hysteresis test(s) failed."
exit 1
