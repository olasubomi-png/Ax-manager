#!/usr/bin/env sh
set -u
TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$TEST_DIR/step11_test_lib.sh"

fixture_env healthy
OUT="$(orchestrator stop)"
assert_contains "$OUT" "ORCHESTRATOR_LIFECYCLE=stopped" "stop before start is safe"
OUT="$(orchestrator start SessionArena)"
assert_contains "$OUT" "SESSION_ID=" "session id created"
assert_contains "$OUT" "ORCHESTRATOR_LIFECYCLE=active" "session active after start"
OUT="$(orchestrator start SessionArena)"
assert_contains "$OUT" "already active" "duplicate start is idempotent"
OUT="$(orchestrator status)"
assert_contains "$OUT" "ORCHESTRATOR_LIFECYCLE=active" "status reports active"
OUT="$(orchestrator stop)"
assert_contains "$OUT" "ORCHESTRATOR_LIFECYCLE=stopped" "session stop completes"
assert_contains "$OUT" "RUNTIME_ARTIFACTS_REMAINING=NO" "stop cleans runtime artifacts"
OUT="$(orchestrator stop)"
assert_contains "$OUT" "already stopped" "repeated stop is safe"

fixture_env healthy
ORCH_INTERVAL=0 ORCH_DURATION=1 OUT="$(orchestrator monitor)"
assert_contains "$OUT" "MONITOR_STATUS=completed" "bounded monitor completes"
assert_contains "$OUT" "MONITOR_SAMPLES=" "monitor reports sample count"

fixture_env healthy
ORCH_EVIDENCE_FILE="$TEST_TMP/does-not-exist.env"
OUT="$(orchestrator dry-run)"
assert_contains "$OUT" "DRY_RUN=YES" "provider failure stays dry-run"
assert_contains "$OUT" "SELECTED_STATE=conservative" "provider failure conservative fallback"
assert_contains "$OUT" "EVIDENCE_STATUS=UNKNOWN" "provider failure explicitly unknown"

cleanup_step11_test
printf 'Step 11 lifecycle tests: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
