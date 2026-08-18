#!/system/bin/sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)/gpu_apply_test_lib.sh"
trap cleanup_apply_fixture EXIT HUP INT TERM
setup_apply_fixture
OUTPUT="$(run_gpu_apply restore 2>&1)"; STATUS=$?
[ "$STATUS" -eq 0 ] && printf '%s\n' "$OUTPUT" | grep -q "no GPU backup" && pass "restore without backup is a no-op" || fail "restore without backup is a no-op"
run_gpu_apply apply performance >/dev/null 2>&1
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 400000000 ] && pass "restore fixture has changed state" || fail "restore fixture has changed state"
OUTPUT="$(run_gpu_apply restore 2>&1)"; STATUS=$?
printf '%s\n' "$OUTPUT" | grep -q "restored safely" && pass "restore succeeds from recorded backup" || fail "restore succeeds from recorded backup"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 500000000 ] && pass "restore returns detected original frequency" || fail "restore returns detected original frequency"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/governor")" = simple_ondemand ] && pass "restore returns detected original governor" || fail "restore returns detected original governor"
[ ! -e "$DATA/runtime/gpu/original_gpu.conf" ] && pass "successful restore removes completed backup" || fail "successful restore removes completed backup"
setup_apply_fixture
run_gpu_apply apply performance >/dev/null 2>&1
printf '%s\n' 400000000 > "$FIXTURE/class/devfreq/mali-g57/target_freq"
OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "backup" && pass "existing backup prevents overwrite" || fail "existing backup prevents overwrite"
[ "$(cat "$FIXTURE/class/devfreq/mali-g57/target_freq")" = 400000000 ] && pass "backup refusal leaves current state unchanged" || fail "backup refusal leaves current state unchanged"
grep -q '^frequency=500000000$' "$DATA/runtime/gpu/original_gpu.conf" && pass "existing backup remains intact" || fail "existing backup remains intact"
setup_apply_fixture
run_gpu_apply apply performance >/dev/null 2>&1
rm -f "$FIXTURE/class/devfreq/mali-g57/target_freq"
OUTPUT="$(run_gpu_apply restore 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "not writable" && pass "restore refuses missing backed-up node" || fail "restore refuses missing backed-up node"
[ -s "$DATA/runtime/gpu/original_gpu.conf" ] && pass "failed restore keeps backup for recovery" || fail "failed restore keeps backup for recovery"
[ "$FAILURES" -eq 0 ] && { echo "All GPU restore tests passed."; exit 0; }
echo "$FAILURES GPU restore test(s) failed."
exit 1
