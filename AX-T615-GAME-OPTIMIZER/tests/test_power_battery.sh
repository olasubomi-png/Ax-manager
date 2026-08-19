#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

for pair in 'battery-high:HIGH' 'battery-medium:MEDIUM' 'battery-low:LOW' 'battery-critical:CRITICAL'; do
    NAME="${pair%%:*}"; EXPECTED="${pair##*:}"
    fixture_env "$NAME"
    OUT="$(controller battery)"
    assert_contains "$OUT" "Battery state: $EXPECTED" "$NAME battery band"
done

fixture_env battery-health-good
assert_contains "$(controller health)" "Battery health: GOOD" "good battery health"
fixture_env battery-health-warning
assert_contains "$(controller health)" "Battery health: OVERHEAT" "warning battery health"
fixture_env unknown
assert_contains "$(controller battery)" "Battery: UNKNOWN%" "unknown battery safe fallback"
cleanup_step10_test
printf 'POWER_BATTERY_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
