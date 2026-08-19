#!/usr/bin/env sh
# Step 12 test contract: final fixture-driven session scenarios prove safety-first orchestration remains deterministic end to end.
set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
MODULE_ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
FIXTURES="$MODULE_ROOT/tests/fixtures/orchestrator"
TMP="${STEP12_E2E_TEST_TMP:-/tmp/axgo-e2e-test-$$}"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }

decision_for() {
    NAME="$1"
    ORCH_EVIDENCE_FILE="$FIXTURES/$NAME/evidence.env" AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/orchestrator-evidence" > "$TMP/$NAME.evidence"
    ORCH_EVIDENCE_FILE="$TMP/$NAME.evidence" AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/orchestrator-decision"
}

HEALTHY=$(decision_for healthy)
contains "$HEALTHY" 'SELECTED_STATE=balanced' "Scenario A healthy gaming stays balanced"
contains "$HEALTHY" 'SAFETY_CLASSIFICATION=READ_ONLY' "Scenario A has no protection claim"

THERMAL=$(decision_for thermal-danger)
contains "$THERMAL" 'SELECTED_STATE=thermal-protection' "Scenario B thermal escalation wins"
contains "$THERMAL" 'PRIORITY=THERMAL' "Scenario B blocks performance priority"
contains "$THERMAL" 'RECOVERY_CONDITIONS=thermal state below caution' "Scenario B requires recovery"

BATTERY=$(decision_for low-battery)
contains "$BATTERY" 'SELECTED_STATE=battery-protection' "Scenario C low battery protects"
contains "$BATTERY" 'PRIORITY=POWER' "Scenario C is conservative power policy"

CONFLICT=$(decision_for conflict)
contains "$CONFLICT" 'SELECTED_STATE=thermal-protection' "Scenario D conflict honors thermal priority"
contains "$CONFLICT" 'RECOMMENDED_ACTIONS=recommend_thermal_protection' "Scenario D does not escalate performance"

UNKNOWN=$(decision_for unknown)
contains "$UNKNOWN" 'SELECTED_STATE=conservative' "Scenario E unavailable telemetry fails safe"
contains "$UNKNOWN" 'EVIDENCE_STATUS=UNKNOWN' "Scenario E exposes unavailable evidence"

RECOVERY=$(decision_for recovery)
contains "$RECOVERY" 'SELECTED_STATE=balanced' "Scenario F recovered evidence returns to balanced decision"
contains "$RECOVERY" 'FORBIDDEN_ACTIONS_BLOCKED=YES' "Scenario F retains safety guard"

SNAPSHOT=$(ORCH_EVIDENCE_FILE="$FIXTURES/conflict/evidence.env" AXGO_ROOT="$MODULE_ROOT" DASHBOARD_RUNTIME_DIR="$TMP/dashboard-runtime" ORCH_RUNTIME_DIR="$TMP/orchestrator" sh "$MODULE_ROOT/bin/dashboard" snapshot)
contains "$SNAPSHOT" '"state":"thermal-protection"' "E2E dashboard preserves core decision"
contains "$SNAPSHOT" '"read_only":true' "E2E dashboard is read-only"
contains "$SNAPSHOT" '"forbidden_actions_blocked":"YES"' "E2E dashboard exposes safety guard"

printf 'STEP12_E2E_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
