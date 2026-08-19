#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

fixture_env battery-high
OUT="$(controller temperature)"
assert_contains "$OUT" "Battery temperature: 32.0°C" "normal battery temperature"
assert_contains "$OUT" "Battery temperature state: NORMAL" "normal temperature state"

fixture_env charging-hot
OUT="$(controller temperature)"
assert_contains "$OUT" "Battery temperature: 50.0°C" "critical battery temperature"
assert_contains "$OUT" "Battery temperature state: CRITICAL" "critical temperature state"

fixture_env missing-temperature
OUT="$(controller temperature)"
assert_contains "$OUT" "Battery temperature: UNKNOWN°C" "missing temperature value"
assert_contains "$OUT" "Battery temperature state: UNKNOWN" "missing temperature state"

fixture_env unknown
OUT="$(controller temperature)"
assert_contains "$OUT" "Battery temperature state: UNKNOWN" "unknown temperature safe fallback"
cleanup_step10_test
printf 'POWER_TEMPERATURE_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
