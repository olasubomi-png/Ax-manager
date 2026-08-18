#!/system/bin/sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)/gpu_apply_test_lib.sh"
trap cleanup_apply_fixture EXIT HUP INT TERM
setup_apply_fixture
OUTPUT="$(GPU_SAFETY_FORCE_NON_ROOT=true run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "root is required" && pass "no-root apply is refused" || fail "no-root apply is refused"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 500000000 ] && pass "no-root apply leaves fixture unchanged" || fail "no-root apply leaves fixture unchanged"
[ ! -e "$DATA/runtime/gpu/original_gpu.conf" ] && pass "no-root apply creates no backup" || fail "no-root apply creates no backup"
GPU_SAFETY_FORCE_NON_ROOT=false GPU_TEST_GOVERNOR=ondemand GPU_TEST_FREQUENCY=400000000
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "supported" && pass "unsupported governor is rejected" || fail "unsupported governor is rejected"
setup_apply_fixture
GPU_TEST_GOVERNOR=performance
GPU_TEST_FREQUENCY=450000000
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "outside detected" && pass "frequency not in detected list is rejected" || fail "frequency not in detected list is rejected"
setup_apply_fixture
GPU_TEST_GOVERNOR=performance
GPU_TEST_FREQUENCY=900000000
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "outside detected" && pass "over-limit frequency is rejected" || fail "over-limit frequency is rejected"
setup_apply_fixture
GPU_TEST_GOVERNOR=performance
GPU_TEST_FREQUENCY=100000000
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "outside detected" && pass "under-limit frequency is rejected" || fail "under-limit frequency is rejected"
setup_apply_fixture
GPU_TEST_GOVERNOR=performance
GPU_TEST_FREQUENCY=400000000
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
printf '%s\n' "$OUTPUT" | grep -q "GPU changes applied safely" && pass "validated apply succeeds in explicit test mode" || fail "validated apply succeeds in explicit test mode"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 400000000 ] && pass "validated frequency was applied to fixture only" || fail "validated frequency was applied to fixture only"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/governor")" = performance ] && pass "validated governor was applied to fixture only" || fail "validated governor was applied to fixture only"
[ -s "$DATA/runtime/gpu/original_gpu.conf" ] && pass "detected original values were backed up" || fail "detected original values were backed up"
grep -q '^frequency=500000000$' "$DATA/runtime/gpu/original_gpu.conf" && pass "backup contains detected original frequency" || fail "backup contains detected original frequency"
grep -q '^frequency_node=' "$DATA/runtime/gpu/original_gpu.conf" && pass "backup contains changed node" || fail "backup contains changed node"
grep -q '^min_freq=200000000$' "$DATA/runtime/gpu/original_gpu.conf" && pass "backup contains detected minimum" || fail "backup contains detected minimum"
grep -q '^max_freq=800000000$' "$DATA/runtime/gpu/original_gpu.conf" && pass "backup contains detected maximum" || fail "backup contains detected maximum"
BEFORE="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
GPU_ALLOW_FIXTURE_APPLY=false
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
AFTER="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "fixture apply" && pass "fixture protection refuses a second apply" || fail "fixture protection refuses a second apply"
[ "$BEFORE" = "$AFTER" ] && pass "rejected fixture apply makes no changes" || fail "rejected fixture apply makes no changes"
[ "$FAILURES" -eq 0 ] && { echo "All GPU apply tests passed."; exit 0; }
echo "$FAILURES GPU apply test(s) failed."
exit 1
