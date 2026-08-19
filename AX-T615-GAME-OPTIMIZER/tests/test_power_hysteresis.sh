#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

fixture_env battery-critical
POWER_THERMAL_STATE=NORMAL; export POWER_THERMAL_STATE
POWER_MEMORY_STATE=NORMAL; export POWER_MEMORY_STATE
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "critical escalation is immediate"

HIGH_FIXTURE="$FIXTURE_ROOT/battery-high"
export POWER_SYSFS_ROOT="$HIGH_FIXTURE/sys/class/power_supply"
export POWER_BATTERY_ROOT="$HIGH_FIXTURE/sys/class/power_supply/battery"
for n in 1 2; do
    OUT="$(guard recommend)"
    assert_contains "$OUT" "Recommendation: PERFORMANCE_BLOCKED" "recovery waits for stable sample $n"
done
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "first recovery step after stable samples"
for n in 1 2; do OUT="$(guard recommend)"; assert_contains "$OUT" "Recommendation: CONSERVATIVE" "one-level recovery hold $n"; done
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: BALANCED" "second recovery step"
for n in 1 2; do OUT="$(guard recommend)"; assert_contains "$OUT" "Recommendation: BALANCED" "balanced recovery hold $n"; done
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: PERFORMANCE_ALLOWED" "final recovery to allowed"

fixture_env charging-hot
OUT="$(guard recommend)"
assert_contains "$OUT" "Recommendation: CONSERVATIVE" "charging-hot remains conservative"
assert_contains "$(cat "$MODULE_ROOT/config/power-policy.json")" '"long_session_minutes": 60' "long session policy configured"
cleanup_step10_test
printf 'POWER_HYSTERESIS_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
