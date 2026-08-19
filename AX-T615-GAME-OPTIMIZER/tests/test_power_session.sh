#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$TEST_DIR/step10_test_lib.sh"

fixture_env battery-high
POWER_THERMAL_STATE=NORMAL; export POWER_THERMAL_STATE
POWER_MEMORY_STATE=NORMAL; export POWER_MEMORY_STATE
OUT="$(controller session-start fixture-game)"
assert_contains "$OUT" "POWER SESSION START" "power session start"
assert_file_exists "$POWER_RUNTIME_DIR/session.started" "session state created"
assert_file_exists "$POWER_RUNTIME_DIR/start.battery" "session battery snapshot"

OUT="$(controller sample)"
assert_contains "$OUT" "Power sample:" "power session sample"
assert_file_exists "$POWER_RUNTIME_DIR/samples" "power samples file"

export POWER_SYSFS_ROOT="$FIXTURE_ROOT/battery-low/sys/class/power_supply"
export POWER_BATTERY_ROOT="$FIXTURE_ROOT/battery-low/sys/class/power_supply/battery"
OUT="$(controller session-stop)"
assert_contains "$OUT" "POWER PERFORMANCE REPORT" "power performance report"
assert_contains "$OUT" "Game: fixture-game" "session game metadata"
assert_contains "$OUT" "Starting battery: 85%" "session start battery"
assert_contains "$OUT" "Ending battery: 20%" "session end battery"
assert_contains "$OUT" "Battery drain: 65.00%" "session drain"
assert_contains "$OUT" "Observed drain rate:" "session drain rate"
assert_contains "$OUT" "Battery temperature:" "session temperature report"
assert_contains "$OUT" "Power state:" "session power state report"
[ ! -e "$POWER_RUNTIME_DIR/session.started" ] && pass "session runtime cleanup" || fail "session runtime cleanup"

OUT="$(controller session-stop)"
assert_contains "$OUT" "No active power session" "stopped session is idempotent"
cleanup_step10_test
printf 'POWER_SESSION_TESTS: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
