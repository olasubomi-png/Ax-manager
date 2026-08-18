#!/system/bin/sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)/gpu_apply_test_lib.sh"
trap cleanup_apply_fixture EXIT HUP INT TERM
setup_apply_fixture
OUTPUT="$(run_gpu_reset 2>&1)"; STATUS=$?
[ "$STATUS" -eq 0 ] && printf '%s\n' "$OUTPUT" | grep -q "no GPU backup" && pass "gpu-reset without backup is safe no-op" || fail "gpu-reset without backup is safe no-op"
run_gpu_apply apply performance >/dev/null 2>&1
OUTPUT="$(run_gpu_reset 2>&1)"; STATUS=$?
printf '%s\n' "$OUTPUT" | grep -q "restored safely" && pass "gpu-reset restores recorded settings" || fail "gpu-reset restores recorded settings"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 500000000 ] && pass "gpu-reset restored original frequency" || fail "gpu-reset restored original frequency"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/governor")" = simple_ondemand ] && pass "gpu-reset restored original governor" || fail "gpu-reset restored original governor"
[ ! -e "$DATA/runtime/gpu/original_gpu.conf" ] && pass "gpu-reset removes backup after success" || fail "gpu-reset removes backup after success"
[ "$FAILURES" -eq 0 ] && { echo "All GPU reset tests passed."; exit 0; }
echo "$FAILURES GPU reset test(s) failed."
exit 1
