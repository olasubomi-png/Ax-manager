#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"
BEFORE="$(fixture_checksum)"

fixture_env battery-high
OUT="$(controller status)"
assert_contains "$OUT" "Battery: 85%" "high battery percentage"
assert_contains "$OUT" "Battery state: HIGH" "high battery classification"
assert_contains "$OUT" "Power state: OPTIMAL" "high battery optimal state"
assert_contains "$OUT" "Estimated power: 2.000 W (ESTIMATED)" "estimated power label"
assert_contains "$(controller inspect)" "Read-only: YES" "inspect read-only guarantee"

fixture_env battery-critical
OUT="$(controller status)"
assert_contains "$OUT" "Battery state: CRITICAL" "critical battery classification"
assert_contains "$OUT" "Power state: BATTERY_CRITICAL" "critical power state"

fixture_env unknown
OUT="$(controller status)"
assert_contains "$OUT" "Battery: UNKNOWN%" "unknown battery value"
assert_contains "$OUT" "Battery temperature state: UNKNOWN" "unknown temperature state"
assert_contains "$OUT" "Power state: UNKNOWN" "unknown power state"

fixture_env dumpsys-only
OUT="$(controller status)"
assert_contains "$OUT" "Battery: 72%" "dumpsys battery percentage"
assert_contains "$OUT" "Charging: CHARGING" "dumpsys charging state"
assert_contains "$OUT" "Battery health: GOOD" "dumpsys health"
assert_contains "$OUT" "Battery temperature: 33.0°C" "dumpsys temperature"

fixture_env battery-high
OUT="$(AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/axgo" power status)"
assert_contains "$OUT" "POWER STATUS" "axgo power route"
assert_fixtures_unchanged "$BEFORE" "power fixtures remain immutable"
cleanup_step10_test
printf 'POWER_CONTROLLER_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
