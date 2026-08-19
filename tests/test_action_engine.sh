#!/usr/bin/env sh
# Phase 15 contract: fixed capability-gated actions are dry-run only and never control a device.
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
run_vegas() { FIXTURE=$1; shift; ORCH_EVIDENCE_FILE="$FIXTURE" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$VEGAS" "$@"; }

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
contains 'status identifies capability-gated actions' "$STATUS" 'VEGAS-INJECT CAPABILITY-GATED ACTIONS'
contains 'default mode is dry run' "$STATUS" 'MODE=DRY_RUN'
contains 'real device apply is unavailable' "$STATUS" 'REAL_DEVICE_APPLY=NOT_AVAILABLE'
contains 'device capabilities remain unverified' "$STATUS" 'DEVICE_CAPABILITIES=UNVERIFIED'
contains 'safety gate remains enforced' "$STATUS" 'SAFETY_GATE=ENFORCED'
contains 'status scopes action layer to fixed dry runs' "$STATUS" 'ACTION_LAYER_SCOPE=FIXED_CAPABILITY_GATED_DRY_RUN_ONLY'

SNAPSHOT=$(run_engine "$GOOD" snapshot)
contains 'snapshot is read only' "$SNAPSHOT" '"read_only":true'
contains 'snapshot has no device apply' "$SNAPSHOT" '"real_device_apply":"NOT_AVAILABLE"'
contains 'snapshot separates supported actions' "$SNAPSHOT" '"available_actions":"refresh_telemetry,profile_balanced_advisory"'
contains 'snapshot declares unsupported device actions' "$SNAPSHOT" '"unsupported_actions":"profile_performance_advisory,thermal_protection_advisory,memory_conservative_advisory,battery_conservative_advisory"'
contains 'snapshot excludes hardware writes' "$SNAPSHOT" '"hardware_writes":false'

CAPS=$(run_engine "$GOOD" capabilities)
contains 'capabilities expose fixed operations' "$CAPS" 'OPERATIONS=status,capabilities,plan,validate,dry-run,apply--dry-run,verify,rollback,history,lock,unlock'
contains 'capabilities expose fixed allowlist' "$CAPS" 'FIXED_ACTIONS=refresh_telemetry,profile_balanced_advisory,profile_performance_advisory,thermal_protection_advisory,memory_conservative_advisory,battery_conservative_advisory'
contains 'capabilities block hardware writes' "$CAPS" 'HARDWARE_WRITES=BLOCKED'
contains 'capabilities block arbitrary executable paths' "$CAPS" 'ARBITRARY_EXECUTABLE_PATHS=BLOCKED'
contains 'capabilities limit rollback to no applied actions' "$CAPS" 'ROLLBACK=NO_APPLIED_DEVICE_ACTIONS'

PLAN=$(run_engine "$GOOD" plan refresh_telemetry)
contains 'plan retains a fixed action identifier' "$PLAN" 'ACTION_ID=refresh_telemetry'
contains 'plan remains dry run' "$PLAN" 'DRY_RUN=YES'
contains 'plan validates bounded policy context' "$PLAN" 'VALIDATION_RESULT=VALID'
contains 'plan denies device execution' "$PLAN" 'DEVICE_ACTION_EXECUTION=NOT_AVAILABLE'
[ ! -e "$RUNTIME/managed-state" ] && ok 'planning never creates a managed-state marker' || not_ok 'planning never creates a managed-state marker'

VALIDATE=$(run_engine "$GOOD" validate refresh_telemetry)
contains 'validation reports a fixed validation-only result' "$VALIDATE" 'VALIDATION_RESULT=VALID'
contains 'validation has no device effect' "$VALIDATE" 'HARDWARE_WRITES=NO'

DRY=$(run_engine "$GOOD" dry-run refresh_telemetry)
contains 'dry run returns a validated non-application result' "$DRY" 'RESULT=DRY_RUN_VALIDATED'
[ -f "$RUNTIME/audit.log" ] && ok 'dry run records bounded local audit only' || not_ok 'dry run records bounded local audit only'
[ ! -e "$RUNTIME/managed-state" ] && ok 'dry run never changes managed state' || not_ok 'dry run never changes managed state'

fails 'unknown action identifiers are rejected' run_engine "$GOOD" plan ../../../outside
fails 'blocked action categories are rejected' run_engine "$GOOD" plan gpu_governor
UNSUPPORTED=$(run_engine "$GOOD" validate profile_performance_advisory 2>&1 || :)
contains 'unverified performance capability is denied' "$UNSUPPORTED" 'UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED'
contains 'unverified performance capability stays dry run' "$UNSUPPORTED" 'DRY_RUN=YES'

NO_INTENT=$(run_engine "$GOOD" apply refresh_telemetry no-intent 2>&1 || :)
contains 'apply denies every real action spelling' "$NO_INTENT" 'ACTION_DENIED=REAL_DEVICE_APPLY_NOT_AVAILABLE'
APPLY_DRY=$(run_engine "$GOOD" apply refresh_telemetry --dry-run)
contains 'apply permits only explicit dry-run intent' "$APPLY_DRY" 'RESULT=DRY_RUN_VALIDATED'
[ ! -e "$RUNTIME/managed-state" ] && ok 'apply dry-run leaves managed state absent' || not_ok 'apply dry-run leaves managed state absent'

UNKNOWN_UNLOCK=$(run_engine "$UNKNOWN" unlock --explicit-unlock 2>&1 || :)
contains 'unknown safety evidence cannot unlock actions' "$UNKNOWN_UNLOCK" 'UNLOCK_DENIED=SAFETY_EVIDENCE_NOT_VALIDATED'
STALE_DRY=$(run_engine "$STALE" dry-run refresh_telemetry 2>&1 || :)
contains 'stale evidence is denied even in dry-run validation' "$STALE_DRY" 'RESULT=ACTION_DENIED'
contains 'stale evidence exposes dry-run mode' "$STALE_DRY" 'MODE=DRY_RUN'

UNLOCK=$(run_engine "$GOOD" unlock --explicit-unlock)
contains 'validated safe evidence can unlock dry-run planning only' "$UNLOCK" 'ACTION_LOCK=DISABLED'
contains 'unlock cannot enable device apply' "$UNLOCK" 'REAL_DEVICE_APPLY=NOT_AVAILABLE'
VERIFY=$(run_engine "$GOOD" verify refresh_telemetry)
contains 'verification reports no applied action' "$VERIFY" 'RESULT=NOT_APPLIED'
ROLLBACK=$(run_engine "$GOOD" rollback refresh_telemetry)
contains 'rollback reports no applied action' "$ROLLBACK" 'ROLLBACK_RESULT=NO_APPLIED_ACTION'

I=1
while [ "$I" -le 20 ]; do run_engine "$GOOD" dry-run refresh_telemetry >/dev/null || :; I=$((I + 1)); done
HISTORY_OUTPUT=$(run_engine "$GOOD" history)
COUNT=$(printf '%s\n' "$HISTORY_OUTPUT" | grep -c '^ACTION_AUDIT|')
[ "$COUNT" -le 16 ] && ok 'audit history remains bounded to sixteen records' || not_ok 'audit history remains bounded to sixteen records'
contains 'audit records exclude personal data' "$HISTORY_OUTPUT" 'personal_data=NO'
contains 'audit records exclude network transmission' "$HISTORY_OUTPUT" 'network_transmission=NO'
contains 'audit records declare no hardware change' "$HISTORY_OUTPUT" 'hardware_changed=NO'

run_engine "$GOOD" lock >/dev/null
LOCK_AFTER=$(run_engine "$GOOD" status)
contains 'explicit lock restores the default locked state' "$LOCK_AFTER" 'ACTION_LOCK=ENABLED'

VEGAS_ACTION=$(run_vegas "$GOOD" action snapshot)
contains 'VEGAS public action route exposes action-engine schema' "$VEGAS_ACTION" '"component":"vegas-capability-gated-action-engine"'
contains 'VEGAS action snapshot has no device apply' "$VEGAS_ACTION" '"real_device_apply":"NOT_AVAILABLE"'
VEGAS_GATE=$(run_vegas "$GOOD" action evaluate)
contains 'VEGAS legacy action gate remains simulation only' "$VEGAS_GATE" '"source":"vegas-inject-action-safety-gate"'
fails 'VEGAS rejects missing fixed action argument' sh "$VEGAS" action apply
PLUGIN_ACTION=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$MANAGER" invoke ax-t615-game-optimizer action snapshot)
contains 'AX-T615 plugin action snapshot remains fixed' "$PLUGIN_ACTION" '"mode":"DRY_RUN"'
fails 'plugin manager rejects arbitrary action route' sh "$MANAGER" invoke ax-t615-game-optimizer action ../../outside

SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
run_vegas "$GOOD" action snapshot >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'capability-gated actions preserve System Observer isolation' || not_ok 'capability-gated actions preserve System Observer isolation'

UNIFIED=$(run_vegas "$GOOD" snapshot)
contains 'unified snapshot retains legacy controlled-action envelope' "$UNIFIED" '"action":{"schema":"1","source":"vegas-inject-controlled-action-engine"'
contains 'unified snapshot includes capability-gated action envelope' "$UNIFIED" '"capability_action":{"schema":"1","component":"vegas-capability-gated-action-engine"'
contains 'unified snapshot includes separate action-gate envelope' "$UNIFIED" '"action_gate":{"schema":"1"'
DASH=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_EVIDENCE_RUNTIME_DIR="$HISTORY" VEGAS_ACTION_RUNTIME_DIR="$RUNTIME" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot retains legacy controlled-action envelope' "$DASH" '"action":{"schema":"1","source":"vegas-inject-controlled-action-engine"'
contains 'dashboard snapshot includes capability-gated action envelope' "$DASH" '"capability_action":{"schema":"1","component":"vegas-capability-gated-action-engine"'
contains 'dashboard snapshot retains action-gate envelope' "$DASH" '"action_gate":{"schema":"1"'
for ID in actionDeviceCapabilities actionRealDeviceApply actionSafetyGate actionAvailableActions actionUnsupportedActions actionRollback actionAuditHistory; do
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

printf 'PHASE15_ACTION_ENGINE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
