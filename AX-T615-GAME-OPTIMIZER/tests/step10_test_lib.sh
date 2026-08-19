#!/usr/bin/env sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(CDPATH= cd -- "$TEST_DIR/.." && pwd)"
FIXTURE_ROOT="$MODULE_ROOT/tests/fixtures/power"
TEST_TMP="${STEP10_TEST_TMP:-/tmp/axgo-step10-tests-$$}"
mkdir -p "$TEST_TMP"

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_contains() { HAYSTACK="$1"; NEEDLE="$2"; LABEL="${3:-contains}"; printf '%s\n' "$HAYSTACK" | grep -Fq "$NEEDLE" && pass "$LABEL" || fail "$LABEL (missing: $NEEDLE)"; }
assert_not_contains() { HAYSTACK="$1"; NEEDLE="$2"; LABEL="${3:-not-contains}"; if printf '%s\n' "$HAYSTACK" | grep -Fq "$NEEDLE"; then fail "$LABEL (unexpected: $NEEDLE)"; else pass "$LABEL"; fi; }
assert_equal() { ACTUAL="$1"; EXPECTED="$2"; LABEL="${3:-equal}"; if [ "$ACTUAL" = "$EXPECTED" ]; then pass "$LABEL"; else fail "$LABEL (expected '$EXPECTED', got '$ACTUAL')"; fi; }
assert_success() { LABEL="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$LABEL"; else fail "$LABEL (command failed)"; fi; }
assert_file_exists() { [ -e "$1" ] && pass "${2:-file exists}" || fail "${2:-file exists} ($1)"; }

fixture_env() {
    NAME="$1"
    FIXTURE="$FIXTURE_ROOT/$NAME"
    export POWER_SYSFS_ROOT="$FIXTURE/sys/class/power_supply"
    export POWER_BATTERY_ROOT="$FIXTURE/sys/class/power_supply/battery"
    export POWER_DUMPSYS_FILE=""
    [ -r "$FIXTURE/dumpsys.battery" ] && export POWER_DUMPSYS_FILE="$FIXTURE/dumpsys.battery"
    export POWER_POLICY_FILE="$MODULE_ROOT/config/power-policy.json"
    export POWER_DATA_ROOT="$TEST_TMP/data-$NAME"
    export POWER_GUARD_DATA_ROOT="$POWER_DATA_ROOT"
    export POWER_RUNTIME_DIR="$POWER_DATA_ROOT/runtime/power"
    export POWER_LOG_FILE="$POWER_DATA_ROOT/logs/power.log"
    export POWER_THERMAL_STATE="NORMAL"
    export POWER_MEMORY_STATE="NORMAL"
    export POWER_CHARGING_GAMING_MODE="NORMAL"
    unset POWER_PROFILE_TARGET POWER_PROFILE_RECOMMENDATION GAME_PROFILE_RECOMMENDATION POWER_FPS_RECOMMENDATION POWER_FPS_STATE
    rm -rf "$POWER_DATA_ROOT"
    mkdir -p "$POWER_DATA_ROOT"
}

reset_env() {
    unset POWER_SYSFS_ROOT POWER_BATTERY_ROOT POWER_DUMPSYS_FILE POWER_THERMAL_STATE POWER_MEMORY_STATE POWER_CHARGING_GAMING_MODE POWER_PROFILE_TARGET POWER_PROFILE_RECOMMENDATION GAME_PROFILE_RECOMMENDATION POWER_FPS_RECOMMENDATION POWER_FPS_STATE
}

controller() { sh "$MODULE_ROOT/bin/power-controller" "$@"; }
guard() { sh "$MODULE_ROOT/bin/power-guard" "$@"; }
monitor() { sh "$MODULE_ROOT/bin/power-monitor" "$@"; }

fixture_checksum() {
    find "$FIXTURE_ROOT" -type f -print | sort | while IFS= read -r FILE; do
        sha256sum "$FILE"
    done
}

assert_fixtures_unchanged() {
    BEFORE="$1"; AFTER="$(fixture_checksum)"; LABEL="${2:-fixtures unchanged}"
    assert_equal "$AFTER" "$BEFORE" "$LABEL"
}

cleanup_step10_test() {
    reset_env
    rm -rf "$TEST_TMP"
}
