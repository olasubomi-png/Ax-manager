#!/usr/bin/env sh
# Action Safety Gate contract: fixed simulation only, internally derived policy context, and no real action execution.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
GATE="$ROOT/bin/action-gate"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
PLUGIN_META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
TMP="${ACTION_GATE_TEST_TMP:-$ROOT/tests/.tmp/action-gate-$$}"
AUDIT="$TMP/audit"
ACTION_RUNTIME="$TMP/action-runtime"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/plugin.json" ] && cp "$TMP/plugin.json" "$PLUGIN_META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$AUDIT" "$ACTION_RUNTIME" || exit 1
cp "$PLUGIN_META" "$TMP/plugin.json"

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
run_gate() { FIXTURE=$1; shift; ORCH_EVIDENCE_FILE="$FIXTURE" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$GATE" "$@"; }

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
SESSION_ID=action-gate-test-session
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

STATUS=$(run_gate "$GOOD" status)
contains 'status identifies the fixed action safety gate' "$STATUS" 'VEGAS-INJECT ACTION SAFETY GATE'
contains 'status fixes simulation-only execution mode' "$STATUS" 'Execution mode: SIMULATION_ONLY'
contains 'status declares real actions unavailable' "$STATUS" 'Real action execution: NOT_AVAILABLE'
contains 'status excludes hardware writes' "$STATUS" 'Hardware writes: NO'

CAPS=$(run_gate "$GOOD" capabilities)
contains 'capabilities expose only four fixed operations' "$CAPS" 'ACTION_GATE_CAPABILITIES=status,evaluate,simulate,capabilities'
contains 'capabilities reject caller-supplied actions' "$CAPS" 'CALLER_SUPPLIED_ACTIONS=REJECTED'
contains 'capabilities require internally derived policy requests' "$CAPS" 'INTERNALLY_DERIVED_POLICY_REQUESTS=YES'
contains 'capabilities exclude arbitrary execution' "$CAPS" 'ARBITRARY_EXECUTION=NO'

EVALUATED=$(run_gate "$GOOD" evaluate)
contains 'low-confidence healthy evidence remains blocked by the gate' "$EVALUATED" '"gate_state":"BLOCKED"'
contains 'low-confidence policy explains conservative blocking' "$EVALUATED" 'confidence LOW is insufficient for simulation'
contains 'evaluation remains simulation only' "$EVALUATED" '"execution_mode":"SIMULATION_ONLY"'
contains 'evaluation marks real execution unavailable' "$EVALUATED" '"real_action_execution":"NOT_AVAILABLE"'
contains 'evaluation records internally derived request source' "$EVALUATED" '"caller_input":"NOT_ACCEPTED"'
[ ! -e "$AUDIT/simulation-audit.log" ] && ok 'evaluate does not append an audit record' || not_ok 'evaluate does not append an audit record'

SIMULATED=$(run_gate "$GOOD" simulate)
contains 'simulate preserves blocked state for insufficient confidence' "$SIMULATED" '"simulation_status":"SIMULATION_BLOCKED"'
contains 'simulate marks audit append in output' "$SIMULATED" '"appended_after_simulation":"YES"'
grep -F 'real_action_execution=NOT_AVAILABLE' "$AUDIT/simulation-audit.log" >/dev/null 2>&1 && ok 'simulation audit records no real execution' || not_ok 'simulation audit records no real execution'
[ ! -e "$ACTION_RUNTIME/managed-state" ] && ok 'simulation never changes controlled-action managed state' || not_ok 'simulation never changes controlled-action managed state'

UNKNOWN_RESULT=$(run_gate "$UNKNOWN" evaluate)
contains 'unknown evidence blocks the gate' "$UNKNOWN_RESULT" '"gate_state":"BLOCKED"'
contains 'unknown evidence simulates conservative recommendation only' "$UNKNOWN_RESULT" '"simulated_recommendation":"remain_conservative"'
STALE_RESULT=$(run_gate "$STALE" evaluate)
contains 'stale evidence blocks the gate' "$STALE_RESULT" '"gate_state":"BLOCKED"'
contains 'stale evidence reports insufficient quality reason' "$STALE_RESULT" 'not sufficient for simulation'

fails 'unknown Action Safety Gate operations are rejected' run_gate "$GOOD" apply
fails 'extra caller-supplied action data is rejected' run_gate "$GOOD" simulate gpu_governor
fails 'path-like caller input is rejected' run_gate "$GOOD" ../../outside

I=1
while [ "$I" -le 20 ]; do run_gate "$GOOD" simulate >/dev/null; I=$((I + 1)); done
COUNT=$(awk 'END { print NR + 0 }' "$AUDIT/simulation-audit.log" 2>/dev/null)
[ "$COUNT" -le 16 ] && ok 'simulation audit history remains bounded to sixteen records' || not_ok 'simulation audit history remains bounded to sixteen records'
not_contains 'simulation audit excludes personal identifiers' "$(cat "$AUDIT/simulation-audit.log")" 'credential='
not_contains 'simulation audit excludes network transmission' "$(cat "$AUDIT/simulation-audit.log")" 'network_transmission=YES'

VEGAS_ACTION=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$VEGAS" action evaluate)
contains 'VEGAS public action route exposes gate schema' "$VEGAS_ACTION" '"source":"vegas-inject-action-safety-gate"'
contains 'VEGAS public action route remains simulation only' "$VEGAS_ACTION" '"real_action_execution":"NOT_AVAILABLE"'
fails 'VEGAS public action route rejects legacy apply operation' sh "$VEGAS" action apply
PLUGIN_ACTION=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$MANAGER" invoke ax-t615-game-optimizer action status)
contains 'AX-T615 plugin action route delegates only to gate' "$PLUGIN_ACTION" 'VEGAS-INJECT ACTION SAFETY GATE'
fails 'plugin manager rejects arbitrary action gate route' sh "$MANAGER" invoke ax-t615-game-optimizer action ../../outside
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
ORCH_EVIDENCE_FILE="$GOOD" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$VEGAS" action evaluate >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'action gate preserves System Observer isolation' || not_ok 'action gate preserves System Observer isolation'

UNIFIED=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$VEGAS" snapshot)
contains 'unified snapshot includes simulation-only action gate envelope' "$UNIFIED" '"action_gate":{"schema":"1"'
DASH=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot includes simulation-only action gate envelope' "$DASH" '"action_gate":{"schema":"1"'
for ID in actionGateState actionGateReason actionGateMode actionGateSimulation actionGateRecommendation actionGateConfidence actionGateEvidenceQuality actionGatePolicyState actionGateRequestSource actionGateRealAction actionGateAuditCount actionGateAuditBound actionGateTimestamp; do
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard renders $ID through text bindings" || not_ok "dashboard renders $ID through text bindings"
done

printf '%s\n' '{"id":"ax-t615-game-optimizer","name":"AX-T615 Game Optimizer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":true,"hardware_writes":false,"exec":"do-not-run","minimum_app_version":"1.0.0"}' > "$PLUGIN_META"
INVALID_META=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains 'unsafe executable metadata remains rejected' "$INVALID_META" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED'
cp "$TMP/plugin.json" "$PLUGIN_META"

contains 'tests use repository-local temporary directory' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'action gate contains no hard-coded temporary directory' "$(grep -n '/tmp/' "$GATE" 2>/dev/null || :)" '/tmp/'
for TARGET in "$GATE" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$GATE" >/dev/null 2>&1 && not_ok 'action gate excludes unsafe control and network primitives' || ok 'action gate excludes unsafe control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'ACTION_SAFETY_GATE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
