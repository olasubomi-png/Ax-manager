#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

fixture_env battery-high
OUT="$(controller estimate)"
assert_contains "$OUT" "Power: 2.000 W (ESTIMATED)" "estimated electrical power"
assert_contains "$OUT" "not total device power consumption" "estimation limitation"

fixture_env missing-current
OUT="$(controller estimate)"
assert_contains "$OUT" "Power: UNAVAILABLE" "missing current unavailable estimate"

fixture_env dumpsys-only
OUT="$(controller inspect)"
assert_contains "$OUT" "Voltage: 4.100 V" "dumpsys voltage normalization"

fixture_env battery-high
OUT="$(controller status)"
assert_contains "$OUT" "Voltage: 4.000 V" "voltage normalization"
assert_contains "$OUT" "Current: 0.500 A" "current normalization"
cleanup_step10_test
printf 'POWER_ESTIMATION_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
