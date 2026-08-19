#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"
BEFORE="$(fixture_checksum)"

fixture_env battery-high
POWER_THERMAL_STATE=NORMAL; export POWER_THERMAL_STATE
POWER_MEMORY_STATE=NORMAL; export POWER_MEMORY_STATE
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_ALLOWED" "normal high battery allows performance"
assert_contains "$OUT" "CPU recommendation forwarded" "CPU forwarding is logical only"
assert_contains "$OUT" "GPU recommendation forwarded" "GPU forwarding is logical only"

fixture_env battery-low
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "low battery conservative"

fixture_env battery-critical
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "critical battery blocks performance"

fixture_env charging-hot
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "charging hot conservative"

fixture_env battery-high
POWER_THERMAL_STATE=CRITICAL; export POWER_THERMAL_STATE
POWER_MEMORY_STATE=NORMAL; export POWER_MEMORY_STATE
OUT="$(guard check)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "critical thermal blocks performance"

fixture_env battery-high
POWER_THERMAL_STATE=NORMAL; export POWER_THERMAL_STATE
POWER_MEMORY_STATE=CRITICAL; export POWER_MEMORY_STATE
OUT="$(guard check)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "critical memory blocks performance"

fixture_env unknown
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "unknown power fails safe"

fixture_env battery-high
POWER_PROFILE_RECOMMENDATION=PERFORMANCE_BLOCKED; export POWER_PROFILE_RECOMMENDATION
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "profile block is restrictive"

fixture_env battery-high
POWER_CHARGING_GAMING_MODE=CONSERVATIVE; export POWER_CHARGING_GAMING_MODE
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "conservative charging mode"

fixture_env battery-high
OUT="$(guard dry-run)"
assert_contains "$OUT" "POWER GUARD DRY-RUN" "guard dry-run route"
assert_contains "$OUT" "Read-only: YES" "guard read-only output"
assert_fixtures_unchanged "$BEFORE" "guard fixtures remain immutable"
cleanup_step10_test
printf 'POWER_GUARD_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
