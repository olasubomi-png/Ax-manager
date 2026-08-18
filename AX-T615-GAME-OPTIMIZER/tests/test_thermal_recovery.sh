#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
GUARD="$ROOT_DIR/bin/thermal-guard"
FIXTURE="$TEST_DIR/fixtures/thermal"
WORK="${TMPDIR:-/tmp}/axgo-thermal-recovery.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$WORK/fixtures"
for pair in 'critical 56000' 'throttled 51000' 'caution 46000' 'normal 42000'; do
    set -- $pair
    cp -R "$FIXTURE/normal" "$WORK/fixtures/$1"
    printf '%s\n' "$2" > "$WORK/fixtures/$1/thermal_zone0/temp"
done
run() {
    FIX="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" THERMAL_DATA_ROOT="$WORK/data" \
    THERMAL_SYSFS_ROOT="$WORK/fixtures/$FIX" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" \
        sh "$GUARD" "$@"
}
run critical game-start recovery >/dev/null
OUTPUT="$(run critical recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CRITICAL" && pass "critical state detected" || fail "critical state detected"
OUTPUT="$(run throttled recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CRITICAL" && pass "critical recovery sample 1 held" || fail "critical recovery sample 1 held"
OUTPUT="$(run throttled recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CRITICAL" && pass "critical recovery sample 2 held" || fail "critical recovery sample 2 held"
OUTPUT="$(run throttled recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: THROTTLED" && pass "critical recovers to throttled after stable samples" || fail "critical recovers to throttled after stable samples"
OUTPUT="$(run caution recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: THROTTLED" && pass "throttled recovery sample 1 held" || fail "throttled recovery sample 1 held"
OUTPUT="$(run caution recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: THROTTLED" && pass "throttled recovery sample 2 held" || fail "throttled recovery sample 2 held"
OUTPUT="$(run caution recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "throttled recovers to caution after stable samples" || fail "throttled recovers to caution after stable samples"
OUTPUT="$(run normal recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "caution recovery sample 1 held" || fail "caution recovery sample 1 held"
OUTPUT="$(run normal recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: CAUTION" && pass "caution recovery sample 2 held" || fail "caution recovery sample 2 held"
OUTPUT="$(run normal recommend)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal state: NORMAL" && pass "recovery reaches normal after stable samples" || fail "recovery reaches normal after stable samples"
run normal game-stop >/dev/null
[ "$FAILURES" -eq 0 ] && { echo "All thermal recovery tests passed."; exit 0; }
echo "$FAILURES thermal recovery test(s) failed."
exit 1
