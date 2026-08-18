#!/system/bin/sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)/gpu_apply_test_lib.sh"
trap cleanup_apply_fixture EXIT HUP INT TERM
for recommendation in BOOST BALANCED CONSERVATIVE BLOCKED UNKNOWN; do
    setup_apply_fixture
    THERMAL_GUARD_RECOMMENDATION="$recommendation"
    THERMAL_GUARD_STATE=NORMAL
    GPU_ALLOW_FIXTURE_APPLY=false
    OUTPUT="$(run_gpu_apply apply performance 2>&1)"; STATUS=$?
    case "$recommendation" in
        BOOST)
            [ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "fixture apply" && pass "BOOST reaches guarded apply without changing fixture" || fail "BOOST reaches guarded apply without changing fixture"
            ;;
        BALANCED|CONSERVATIVE|BLOCKED|UNKNOWN)
            [ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "thermal guard denied" && pass "$recommendation denies performance apply" || fail "$recommendation denies performance apply"
            ;;
    esac
done
setup_apply_fixture
THERMAL_GUARD_RECOMMENDATION=UNKNOWN
GPU_ALLOW_FIXTURE_APPLY=false
OUTPUT="$(run_gpu_apply apply cool 2>&1)"; STATUS=$?
[ "$STATUS" -ne 0 ] && printf '%s\n' "$OUTPUT" | grep -q "thermal guard denied" && pass "UNKNOWN remains fail-safe for cool" || fail "UNKNOWN remains fail-safe for cool"
[ "$FAILURES" -eq 0 ] && { echo "All GPU thermal guard tests passed."; exit 0; }
echo "$FAILURES GPU thermal guard test(s) failed."
exit 1
