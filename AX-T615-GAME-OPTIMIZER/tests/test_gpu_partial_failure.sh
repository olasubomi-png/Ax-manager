#!/system/bin/sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)/gpu_apply_test_lib.sh"
trap cleanup_apply_fixture EXIT HUP INT TERM
setup_apply_fixture
GPU_TEST_FAIL_AFTER_GOVERNOR=true
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "rolled back" && pass "partial failure is reported" || fail "partial failure is reported"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/governor")" = simple_ondemand ] && pass "earlier governor change was rolled back" || fail "earlier governor change was rolled back"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 500000000 ] && pass "frequency remained at original value" || fail "frequency remained at original value"
[ -s "$DATA/runtime/gpu/original_gpu.conf" ] && pass "original backup remains after partial failure" || fail "original backup remains after partial failure"
grep -q '^governor=simple_ondemand$' "$DATA/runtime/gpu/original_gpu.conf" && pass "backup still records original governor" || fail "backup still records original governor"
[ "$FAILURES" -eq 0 ] && { echo "All GPU partial-failure tests passed."; exit 0; }
echo "$FAILURES GPU partial-failure test(s) failed."
exit 1
