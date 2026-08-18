#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/gpu"
CONTROLLER="$ROOT_DIR/bin/gpu-controller"
WORK="${TMPDIR:-/tmp}/axgo-gpu-detection.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run_gpu() {
    SCENARIO="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" GPU_SYSFS_ROOT="$FIXTURE/$SCENARIO" \
    GPU_PROPERTIES_FILE="$FIXTURE/$SCENARIO/properties" THERMAL_GUARD_RECOMMENDATION=BALANCED \
        sh "$CONTROLLER" "$@"
}
mkdir -p "$WORK"
OUTPUT="$(run_gpu missing_frequency status)"
printf '%s\n' "$OUTPUT" | grep -q "GPU control: UNCERTAIN" && pass "missing frequency fails closed" || fail "missing frequency fails closed"
OUTPUT="$(run_gpu missing_governor status)"
printf '%s\n' "$OUTPUT" | grep -q "Governor: UNAVAILABLE" && pass "missing governor is reported" || fail "missing governor is reported"
OUTPUT="$(run_gpu invalid_frequency capabilities)"
printf '%s\n' "$OUTPUT" | grep -q "Current frequency within detected limits: no" && pass "invalid frequency is rejected" || fail "invalid frequency is rejected"
OUTPUT="$(run_gpu over_max capabilities)"
printf '%s\n' "$OUTPUT" | grep -q "Current frequency within detected limits: no" && pass "frequency over maximum is rejected" || fail "frequency over maximum is rejected"
OUTPUT="$(run_gpu unknown_driver status)"
printf '%s\n' "$OUTPUT" | grep -q "Driver: unknown" && pass "unknown driver is surfaced" || fail "unknown driver is surfaced"
OUTPUT="$(run_gpu missing_devfreq inspect)"
printf '%s\n' "$OUTPUT" | grep -q "Potential GPU interfaces:" && pass "missing devfreq is handled" || fail "missing devfreq is handled"
printf '%s\n' "$OUTPUT" | grep -q -- "- UNAVAILABLE" && pass "missing devfreq reports unavailable" || fail "missing devfreq reports unavailable"
OUTPUT="$(run_gpu readonly capabilities)"
printf '%s\n' "$OUTPUT" | grep -q "GPU writes enabled: NO" && pass "read-only fixture cannot enable writes" || fail "read-only fixture cannot enable writes"
[ "$FAILURES" -eq 0 ] && { echo "All GPU detection tests passed."; exit 0; }
echo "$FAILURES GPU detection test(s) failed."
exit 1
