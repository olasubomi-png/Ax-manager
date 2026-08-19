#!/usr/bin/env sh
set -u
TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$TEST_DIR/step11_test_lib.sh"

PRODUCTION_FILES="$MODULE_ROOT/bin/orchestrator $MODULE_ROOT/bin/orchestrator-evidence $MODULE_ROOT/bin/orchestrator-decision"
FORBIDDEN=0
for FILE in $PRODUCTION_FILES; do
    if grep -nE '(^|[;&|[:space:]])(kill|pkill|killall|setprop|sysctl|swapoff|swapon|renice|chrt)([[:space:]]|$)|settings[[:space:]]+put|am[[:space:]]+force-stop|>[[:space:]]*/(proc|sys)/|tee[[:space:]]+[^[:space:]]*/(proc|sys)/|chmod[[:space:]]+[^[:space:]]*/(proc|sys)/|chown[[:space:]]+[^[:space:]]*/(proc|sys)/' "$FILE" >/tmp/step11-safety-match 2>/dev/null; then
        cat /tmp/step11-safety-match >&2
        FORBIDDEN=1
    fi
done
if [ "$FORBIDDEN" -eq 0 ]; then pass "static forbidden-write scan"; else fail "static forbidden-write scan"; fi

fixture_env conflict
OUT="$(orchestrator dry-run)"
assert_contains "$OUT" "DRY_RUN=YES" "dry-run is explicit"
assert_contains "$OUT" "BLOCKED_ACTIONS=" "dry-run lists blocked actions"
assert_contains "$OUT" "HARDWARE_WRITES_PERFORMED=NO" "dry-run performs no hardware writes"
assert_contains "$OUT" "FORBIDDEN_ACTIONS_BLOCKED=YES" "dry-run blocks forbidden actions"
assert_contains "$OUT" "recommend_thermal_protection" "dry-run retains safe logical recommendation"

fixture_env low-battery
OUT="$(decision)"
assert_contains "$OUT" "BLOCKED_ACTIONS=write_proc,write_sys,write_power_hal,write_governor,write_charging_limit,modify_battery,kill_process,force_stop,modify_zram,modify_swap,modify_lmkd,disable_thermal_protection,disable_battery_protection" "complete blocked action set"
assert_not_contains "$OUT" "settings put" "no Android setting command in output"

cleanup_step11_test
printf 'Step 11 safety tests: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
