#!/usr/bin/env sh
set -u
TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$TEST_DIR/step11_test_lib.sh"

fixture_env thermal-danger
OUT="$(orchestrator start ThermalArena)"
assert_contains "$OUT" "ORCHESTRATOR_STATE=thermal-protection" "thermal escalation is immediate"

ORCH_EVIDENCE_FILE="$FIXTURE_ROOT/recovery/evidence.env"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "STABLE_SAMPLES=1" "recovery sample one held"
assert_contains "$OUT" "NEXT_STATE=thermal-protection" "recovery does not jump immediately"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "STABLE_SAMPLES=2" "recovery sample two held"
assert_contains "$OUT" "NEXT_STATE=thermal-protection" "second recovery sample still protected"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "STABLE_SAMPLES=3" "third recovery sample held"
assert_contains "$OUT" "NEXT_STATE=thermal-protection" "third recovery sample still protected"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "NEXT_STATE=recovery" "recovery state entered after stable samples"
OUT="$(orchestrator sample)"
OUT="$(orchestrator sample)"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "STABLE_SAMPLES=3" "recovery exit threshold reached"
assert_contains "$OUT" "NEXT_STATE=recovery" "recovery remains guarded until exit threshold"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "NEXT_STATE=balanced" "recovery exits toward balanced one step at a time"

fixture_env high-demand
OUT="$(orchestrator start DemandArena)"
assert_contains "$OUT" "ORCHESTRATOR_STATE=performance" "performance entry when justified"
ORCH_EVIDENCE_FILE="$FIXTURE_ROOT/oscillation-a/evidence.env"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "ORCHESTRATOR_STATE=performance" "single fluctuation does not thrash performance"
ORCH_EVIDENCE_FILE="$FIXTURE_ROOT/high-demand/evidence.env"
OUT="$(orchestrator sample)"
assert_contains "$OUT" "ORCHESTRATOR_STATE=performance" "stable performance remains performance"

cleanup_step11_test
printf 'Step 11 hysteresis tests: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
