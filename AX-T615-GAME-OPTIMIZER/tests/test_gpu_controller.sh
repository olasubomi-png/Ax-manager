#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/gpu"
CONTROLLER="$ROOT_DIR/bin/gpu-controller"
WORK="${TMPDIR:-/tmp}/axgo-gpu-controller.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run_gpu() {
    SCENARIO="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" GPU_SYSFS_ROOT="$FIXTURE/$SCENARIO" \
    GPU_PROPERTIES_FILE="$FIXTURE/$SCENARIO/properties" THERMAL_GUARD_RECOMMENDATION=BOOST \
        sh "$CONTROLLER" "$@"
}
mkdir -p "$WORK"
OUTPUT="$(run_gpu available status)"
printf '%s\n' "$OUTPUT" | grep -q "Vendor: ARM" && pass "ARM vendor detected" || fail "ARM vendor detected"
printf '%s\n' "$OUTPUT" | grep -q "Model: Mali-G57" && pass "Mali-G57 model detected" || fail "Mali-G57 model detected"
printf '%s\n' "$OUTPUT" | grep -q "Interface: .*/class/devfreq/mali-g57" && pass "devfreq interface detected" || fail "devfreq interface detected"
printf '%s\n' "$OUTPUT" | grep -q "Current frequency: 500000000" && pass "current frequency detected" || fail "current frequency detected"
printf '%s\n' "$OUTPUT" | grep -q "Available frequencies: 200000000 400000000 500000000 800000000" && pass "frequency range detected" || fail "frequency range detected"
printf '%s\n' "$OUTPUT" | grep -q "Governor: simple_ondemand" && pass "governor detected" || fail "governor detected"
printf '%s\n' "$OUTPUT" | grep -q "GPU utilization: 37" && pass "GPU utilization detected" || fail "GPU utilization detected"
printf '%s\n' "$OUTPUT" | grep -q "GPU control: AVAILABLE" && pass "GPU capability is available" || fail "GPU capability is available"
printf '%s\n' "$OUTPUT" | grep -q "Vulkan: AVAILABLE" && pass "Vulkan detected" || fail "Vulkan detected"
printf '%s\n' "$OUTPUT" | grep -q "OpenGL ES: AVAILABLE" && pass "OpenGL ES detected" || fail "OpenGL ES detected"
printf '%s\n' "$OUTPUT" | grep -q "No GPU settings were modified" && pass "status is read-only" || fail "status is read-only"
OUTPUT="$(run_gpu unavailable status)"
printf '%s\n' "$OUTPUT" | grep -q "GPU control: UNAVAILABLE" && pass "unavailable GPU is reported safely" || fail "unavailable GPU is reported safely"
OUTPUT="$(run_gpu missing_utilization status)"
printf '%s\n' "$OUTPUT" | grep -q "GPU utilization: UNAVAILABLE" && pass "missing utilization is not fabricated" || fail "missing utilization is not fabricated"
OUTPUT="$(run_gpu unknown_driver capabilities)"
printf '%s\n' "$OUTPUT" | grep -q "Capability certainty: UNCERTAIN" && pass "unknown driver fails closed" || fail "unknown driver fails closed"
OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data-axgo" GPU_SYSFS_ROOT="$FIXTURE/available" GPU_PROPERTIES_FILE="$FIXTURE/available/properties" THERMAL_GUARD_RECOMMENDATION=BOOST sh "$ROOT_DIR/bin/axgo" gpu info)"
printf '%s\n' "$OUTPUT" | grep -q "Model: Mali-G57" && pass "axgo gpu info route works" || fail "axgo gpu info route works"
BEFORE="$(find "$FIXTURE/available" -type f -exec sha256sum {} \; | sort)"
run_gpu available dry-run performance >/dev/null
AFTER="$(find "$FIXTURE/available" -type f -exec sha256sum {} \; | sort)"
[ "$BEFORE" = "$AFTER" ] && pass "GPU fixture remains unchanged" || fail "GPU fixture remains unchanged"
[ "$FAILURES" -eq 0 ] && { echo "All GPU controller tests passed."; exit 0; }
echo "$FAILURES GPU controller test(s) failed."
exit 1
