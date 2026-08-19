#!/usr/bin/env sh
set -u
TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$TEST_DIR/step11_test_lib.sh"

fixture_env cpu-pressure
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=conservative" "CPU pressure conservative"
assert_contains "$OUT" "PRIORITY=STABILITY" "CPU pressure stability priority"

fixture_env gpu-pressure
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=conservative" "GPU pressure conservative"
assert_contains "$OUT" "PRIORITY=STABILITY" "GPU pressure stability priority"

fixture_env memory-pressure
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=conservative" "memory pressure conservative"
assert_contains "$OUT" "MEMORY_STATE:HIGH_PRESSURE" "memory evidence included"

fixture_env thermal-danger
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=thermal-protection" "thermal danger protection"
assert_contains "$OUT" "SAFETY_CLASSIFICATION=PROTECTION" "thermal protection classification"

fixture_env low-battery
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=battery-protection" "low battery protection"
assert_contains "$OUT" "PRIORITY=POWER" "low battery power priority"

fixture_env health-bad
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=battery-protection" "bad health protection"

fixture_env charging
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=balanced" "normal charging remains balanced"
assert_contains "$OUT" "CHARGING_STATE:CHARGING" "charging evidence included"

fixture_env conflict
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=thermal-protection" "conflict thermal wins over battery"
assert_contains "$OUT" "PRIORITY=THERMAL" "conflict thermal priority"

fixture_env unknown
OUT="$(decision)"
assert_contains "$OUT" "SELECTED_STATE=conservative" "unknown state safe fallback"
assert_contains "$OUT" "SAFETY_CLASSIFICATION=CONSERVATIVE" "unknown conservative classification"

cleanup_step11_test
printf 'Step 11 decision tests: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
