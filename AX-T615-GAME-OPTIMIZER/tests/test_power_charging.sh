#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

fixture_env charging
OUT="$(controller charging)"
assert_contains "$OUT" "Charging: CHARGING" "charging state"
assert_contains "$OUT" "Power source: USB" "USB source"

fixture_env not-charging
OUT="$(controller charging)"
assert_contains "$OUT" "Charging: NOT_CHARGING" "not charging state"

fixture_env charging-hot
OUT="$(controller charging)"
assert_contains "$OUT" "Charging: CHARGING" "charging-hot charging state"
assert_contains "$(controller status)" "Power state: CHARGING_HOT" "charging-hot power state"

fixture_env dumpsys-only
OUT="$(controller charging)"
assert_contains "$OUT" "Charging: CHARGING" "dumpsys charging state"
assert_contains "$OUT" "Power source: USB" "dumpsys USB source"
cleanup_step10_test
printf 'POWER_CHARGING_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
