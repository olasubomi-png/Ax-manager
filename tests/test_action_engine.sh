#!/usr/bin/env sh
# Phase 9 contract: fixed managed-state actions remain locked, validated, bounded, and non-device-controlling.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/bin/action-engine"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
PLUGIN_META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
TMP="${ACTION_TEST_TMP:-$ROOT/tests/.tmp/action-engine-$$}"
RUNTIME="$TMP/runtime"
HISTORY="$TMP/history"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/plugin.json" ] && cp "$TMP/plugin.json" "$PLUGIN_META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$RUNTIME" "$HISTORY" || exit 1
cp "$PLUGIN_META" "$TMP/plugin.json"

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
run_engine() { FIXTURE=$1; shift; ORCH_EVIDENCE_FILE="$FIXTURE" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$ENGINE" "$@"; }

write_fixture() {
    FILE=$1 THERMAL=$2 MEMORY=$3 BATTERY=$4 POWER=$5 AGE=$6 PROFILE=$7
    cat > "$FILE" <<EOF
CPU_UTILIZATION=35
CPU_STATE=NORMAL
GPU_UTILIZATION=35
GPU_STATE=NORMAL
MEMORY_USAGE_PERCENT=$MEMORY
MEMORY_AVAILABLE_MB=1200
MEMORY_STATE=NORMAL
THERMAL_TEMP_C=38
THERMAL_STATE=$THERMAL
THERMAL_TREND=STABLE
FPS=60
FRAME_TIME_MS=16.7
FRAME_PACING=STABLE
FPS_TREND=STABLE
BATTERY_PERCENT=$BATTERY
BATTERY_HEALTH=GOOD
CHARGING_STATE=DISCHARGING
POWER_STATE=$POWER
ESTIMATED_WATTS=4.2
DRAIN_RATE=8.1
EVIDENCE_AGE_SECONDS=$AGE
DISPLAY_REFRESH_HZ=120
PROFILE=$PROFILE
SESSION_ID=action-test-session
SESSION_STATUS=ACTIVE
EOF
}

GOOD="$TMP/good.txt"
STALE="$TMP/stale.txt"
UNKNOWN="$TMP/unknown.txt"
write_fixture "$GOOD" NORMAL 55 68 NORMAL 10 BALANCED
write_fixture "$STALE" NORMAL 55 68 NORMAL 999 BALANCED
cat > "$UNKNOWN" <<'EOF'
THERMAL_STATE=UNKNOWN
BATTERY_PERCENT=UNKNOWN
BATTERY_HEALTH=UNKNOWN
POWER_STATE=UNKNOWN
EVIDENCE_AGE_SECONDS=10
EOF

STATUS=$(run_engine "$GOOD" status)
contains 'status identifies controlled actions' "$STATUS" 'VEGAS-INJECT CONTROLLED ACTIONS'
contains 'default mode is dry run' "$STATUS" 'MODE=DRY_RUN'
contains 'default action lock is enabled' "$STATUS" 'ACTION_LOCK=ENABLED'
contains 'explicit apply is required' "$STATUS" 'EXPLICIT_APPLY_REQUIRED=YES'
contains 'status limits scope to managed state' "$STATUS" 'ACTION_LAYER_SCOPE=VEGAS_INJECT_MANAGED_STATE_ONLY'

CAPS=$(run_engine "$GOOD" capabilities)
contains 'capabilities expose fixed allowlist' "$CAPS" 'ALLOWLIST=refresh_telemetry,reset_recommendation_state,clear_temporary_runtime_state'
contains 'capabilities block hardware writes' "$CAPS" 'HARDWARE_WRITES=BLOCKED'
contains 'capabilities block arbitrary executable paths' "$CAPS" 'ARBITRARY_EXECUTABLE_PATHS=BLOCKED'
contains 'capabilities constrain rollback to managed state' "$CAPS" 'ROLLBACK=FIXED_MANAGED_STATE_ONLY'

PLAN=$(run_engine "$GOOD" plan refresh_telemetry)
contains 'valid plan retains a fixed action identifier' "$PLAN" 'ACTION_ID=refresh_telemetry'
contains 'plan remains dry run' "$PLAN" 'DRY_RUN=YES'
contains 'plan validates bounded policy context' "$PLAN" 'VALIDATION_RESULT=VALID'
[ ! -e "$RUNTIME/managed-state" ] && ok 'planning never changes managed state' || not_ok 'planning never changes managed state'

DRY=$(run_engine "$GOOD" dry-run refresh_telemetry)
contains 'dry run returns a validated non-application result' "$DRY" 'RESULT=DRY_RUN_VALIDATED'
[ ! -e "$RUNTIME/managed-state" ] && ok 'dry run never changes managed state' || not_ok 'dry run never changes managed state'

fails 'unknown action identifiers are rejected' run_engine "$GOOD" plan ../../../outside
fails 'blocked action categories are rejected' run_engine "$GOOD" plan gpu_governor
NO_INTENT=$(run_engine "$GOOD" apply reset_recommendation_state no-intent 2>&1 || :)
contains 'apply denies missing explicit intent' "$NO_INTENT" 'ACTION_DENIED=EXPLICIT_APPLY_INTENT_REQUIRED'
LOCKED=$(run_engine "$GOOD" apply reset_recommendation_state --explicit-apply 2>&1 || :)
contains 'enabled emergency lock denies explicit apply' "$LOCKED" 'ACTION_DENIED=ACTION_LOCK_ENABLED'
[ ! -e "$RUNTIME/managed-state" ] && ok 'locked apply leaves managed state absent' || not_ok 'locked apply leaves managed state absent'

UNKNOWN_UNLOCK=$(run_engine "$UNKNOWN" unlock --explicit-unlock 2>&1 || :)
contains 'unknown safety evidence cannot unlock actions' "$UNKNOWN_UNLOCK" 'UNLOCK_DENIED=SAFETY_EVIDENCE_NOT_VALIDATED'
STALE_DRY=$(run_engine "$STALE" dry-run refresh_telemetry 2>&1 || :)
contains 'stale evidence is denied even in dry-run validation' "$STALE_DRY" 'RESULT=ACTION_DENIED'
contains 'stale evidence exposes dry-run mode' "$STALE_DRY" 'MODE=DRY_RUN'

UNLOCK=$(run_engine "$GOOD" unlock --explicit-unlock)
contains 'validated safe evidence can explicitly unlock managed actions' "$UNLOCK" 'ACTION_LOCK=DISABLED'
APPLIED=$(run_engine "$GOOD" apply reset_recommendation_state --explicit-apply)
contains 'explicit unlocked apply changes only fixed managed state' "$APPLIED" 'RESULT=RESET_MANAGED_RECOMMENDATION_STATE'
grep -F 'MANAGED_STATE=RECOMMENDATION_RESET' "$RUNTIME/managed-state" >/dev/null 2>&1 && ok 'apply writes only expected managed marker' || not_ok 'apply writes only expected managed marker'
COOLDOWN=$(run_engine "$GOOD" apply reset_recommendation_state --explicit-apply 2>&1 || :)
contains 'duplicate action respects fixed cooldown' "$COOLDOWN" 'action cooldown active'

ROLLBACK=$(run_engine "$GOOD" rollback reset_recommendation_state)
contains 'rollback reports fixed managed-state rollback' "$ROLLBACK" 'ROLLBACK_RESULT=MANAGED_STATE_ROLLED_BACK'
[ ! -e "$RUNTIME/managed-state" ] && ok 'rollback removes only fixed managed marker' || not_ok 'rollback removes only fixed managed marker'
mkdir -p "$RUNTIME/execution.lock"
date '+%s' > "$RUNTIME/execution.lock/created_epoch"
CONCURRENT=$(run_engine "$GOOD" rollback clear_temporary_runtime_state 2>&1 || :)
contains 'active execution lock prevents concurrent rollback' "$CONCURRENT" 'ROLLBACK_DENIED=CONCURRENCY_LOCK_ACTIVE'
rm -rf "$RUNTIME/execution.lock"
mkdir -p "$RUNTIME/execution.lock"
printf '%s\n' 0 > "$RUNTIME/execution.lock/created_epoch"
STALE_LOCK=$(run_engine "$GOOD" rollback clear_temporary_runtime_state)
contains 'stale execution lock is recovered for fixed rollback' "$STALE_LOCK" 'ROLLBACK_RESULT=MANAGED_STATE_ROLLED_BACK'

I=1
while [ "$I" -le 20 ]; do run_engine "$GOOD" dry-run refresh_telemetry >/dev/null || :; I=$((I + 1)); done
HISTORY=$(run_engine "$GOOD" history)
COUNT=$(printf '%s\n' "$HISTORY" | grep -c '^ACTION_AUDIT|')
[ "$COUNT" -le 16 ] && ok 'audit history remains bounded to sixteen records' || not_ok 'audit history remains bounded to sixteen records'
contains 'audit records exclude personal data' "$HISTORY" 'personal_data=NO'
contains 'audit records exclude network transmission' "$HISTORY" 'network_transmission=NO'

run_engine "$GOOD" lock >/dev/null
LOCK_AFTER=$(run_engine "$GOOD" status)
contains 'explicit emergency lock restores default locked mode' "$LOCK_AFTER" 'ACTION_LOCK=ENABLED'

VEGAS_ACTION=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$VEGAS" action snapshot)
contains 'VEGAS fixed action route returns action schema' "$VEGAS_ACTION" '"schema":"1"'
fails 'VEGAS rejects arbitrary action routes' sh "$VEGAS" action ../../outside
PLUGIN_ACTION=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$MANAGER" invoke ax-t615-game-optimizer action status)
contains 'AX-T615 plugin action route remains fixed and isolated' "$PLUGIN_ACTION" 'VEGAS-INJECT CONTROLLED ACTIONS'
fails 'plugin manager rejects arbitrary action route' sh "$MANAGER" invoke ax-t615-game-optimizer action ../../outside
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$VEGAS" action snapshot >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'controlled actions preserve System Observer isolation' || not_ok 'controlled actions preserve System Observer isolation'

UNIFIED=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$VEGAS" snapshot)
contains 'unified snapshot includes action envelope' "$UNIFIED" '"action":{"schema":"1"'
DASH=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot includes action envelope' "$DASH" '"action":{"schema":"1"'
for ID in actionMode actionLock actionValidation actionPlannedAction actionResult actionRecommendation actionPolicyState actionEvidenceQuality actionConcurrency actionRollback actionAvailableActions actionBlockedActions actionAuditHistory actionTimestamp; do
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard renders $ID text-safely" || not_ok "dashboard renders $ID text-safely"
done

printf '%s\n' '{"id":"ax-t615-game-optimizer","name":"AX-T615 Game Optimizer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":true,"hardware_writes":false,"exec":"do-not-run","minimum_app_version":"1.0.0"}' > "$PLUGIN_META"
INVALID_META=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains 'unsafe executable metadata remains rejected' "$INVALID_META" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED'
cp "$TMP/plugin.json" "$PLUGIN_META"

contains 'tests use repository-local temporary directory' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'action engine contains no hard-coded temporary directory' "$(grep -n '/tmp/' "$ENGINE" 2>/dev/null || :)" '/tmp/'
for TARGET in "$ENGINE" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$ENGINE" >/dev/null 2>&1 && not_ok 'action engine excludes unsafe control and network primitives' || ok 'action engine excludes unsafe control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'PHASE9_ACTION_ENGINE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
