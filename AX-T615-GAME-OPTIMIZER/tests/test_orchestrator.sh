#!/usr/bin/env sh
set -u
TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$TEST_DIR/step11_test_lib.sh"

BEFORE="$(fixture_checksum)"

fixture_env healthy
OUT="$(decision)"
assert_contains "$OUT" "EVIDENCE_SCHEMA=1" "normalized evidence schema"
assert_contains "$OUT" "SELECTED_STATE=balanced" "healthy state balanced"
assert_contains "$OUT" "CONFIDENCE=HIGH" "healthy confidence high"
assert_contains "$OUT" "RECOMMENDED_ACTIONS=recommend_balanced,collect_telemetry,continue_monitoring" "healthy logical action plan"
assert_contains "$OUT" "BLOCKED_ACTIONS=write_proc" "forbidden actions always blocked"
assert_contains "$OUT" "READ_ONLY=YES" "decision read-only marker"

fixture_env high-demand
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=performance" "high demand performance state"
assert_contains "$OUT" "PRIORITY=FPS" "high demand FPS priority"
assert_contains "$OUT" "recommend_performance" "performance logical recommendation"

fixture_env conflict
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=thermal-protection" "thermal priority over performance and power"
assert_contains "$OUT" "PRIORITY=THERMAL" "thermal priority label"
assert_not_contains "$OUT" "SELECTED_STATE=performance" "thermal cannot be overridden by demand"

fixture_env unknown
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=conservative" "unknown evidence conservative fallback"
assert_contains "$OUT" "CONFIDENCE=LOW" "unknown confidence low"
assert_contains "$OUT" "recommend_conservative" "unknown conservative action"

fixture_env healthy
OUT="$(axgo orchestrator decision)"
assert_contains "$OUT" "DECISION_SCHEMA=1" "axgo orchestrator decision route"
OUT="$(axgo orchestrator dry-run start FixtureArena)"
assert_contains "$OUT" "DRY_RUN=YES" "dry-run route"
assert_contains "$OUT" "HARDWARE_WRITES_PERFORMED=NO" "dry-run no hardware writes"

AFTER="$(fixture_checksum)"
assert_equal "$AFTER" "$BEFORE" "orchestrator fixtures unchanged"

cleanup_step11_test
printf 'Step 11 orchestrator tests: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
