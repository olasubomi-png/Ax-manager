#!/usr/bin/env sh
# Phase 10 control-plane contract: fixed composition of existing read-only engines and simulation-only Action Safety Gate delegation.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
CONTROL="$ROOT/bin/control-plane"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
DASHBOARD_HTML="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/index.html"
PLUGIN="$ROOT/plugins/ax-t615-game-optimizer/plugin.sh"
TMP="${CONTROL_PLANE_TEST_TMP:-$ROOT/tests/.tmp/control-plane-$$}"
RUNTIME="$TMP/runtime"
AUDIT="$TMP/action-gate"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$RUNTIME" "$AUDIT" || exit 1

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }

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
SESSION_ID=control-plane-test-session
SESSION_STATUS=ACTIVE
EOF
}

GOOD="$TMP/good.txt"
UNKNOWN="$TMP/unknown.txt"
write_fixture "$GOOD" NORMAL 55 68 NORMAL 10 BALANCED
cat > "$UNKNOWN" <<'EOF'
THERMAL_STATE=UNKNOWN
BATTERY_PERCENT=UNKNOWN
BATTERY_HEALTH=UNKNOWN
POWER_STATE=UNKNOWN
EVIDENCE_AGE_SECONDS=10
EOF

run_control() { FIXTURE=$1; shift; ORCH_EVIDENCE_FILE="$FIXTURE" VEGAS_CONTROL_PLANE_RUNTIME_DIR="$RUNTIME" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" AXGO_ROOT="$ROOT/AX-T615-GAME-OPTIMIZER" AXGO_DATA_ROOT="$ROOT/AX-T615-GAME-OPTIMIZER" sh "$CONTROL" "$@"; }
run_vegas() { FIXTURE=$1; shift; ORCH_EVIDENCE_FILE="$FIXTURE" VEGAS_CONTROL_PLANE_RUNTIME_DIR="$RUNTIME" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" AXGO_ROOT="$ROOT/AX-T615-GAME-OPTIMIZER" AXGO_DATA_ROOT="$ROOT/AX-T615-GAME-OPTIMIZER" sh "$VEGAS" "$@"; }

STATUS=$(run_control "$GOOD" status)
contains 'status identifies the fixed VEGAS Control Plane' "$STATUS" 'VEGAS CONTROL PLANE'
contains 'status declares simulation only' "$STATUS" 'Simulation only: YES'
contains 'status declares real execution unavailable' "$STATUS" 'Real action execution: NOT_AVAILABLE'
contains 'status declares hardware writes unavailable' "$STATUS" 'Hardware writes: NO'

CAPS=$(run_control "$GOOD" capabilities)
contains 'capabilities expose only five fixed operations' "$CAPS" 'CONTROL_PLANE_CAPABILITIES=status,snapshot,evaluate,simulate,capabilities'
contains 'capabilities exclude dynamic dispatch' "$CAPS" 'DYNAMIC_DISPATCH=NO'
contains 'capabilities exclude process control' "$CAPS" 'PROCESS_CONTROL=NO'
contains 'capabilities exclude arbitrary execution' "$CAPS" 'ARBITRARY_EXECUTION=NO'
contains 'capabilities identify real action layer as unimplemented' "$CAPS" 'REAL_ACTION_LAYER=NOT_IMPLEMENTED'

SNAPSHOT=$(run_control "$GOOD" snapshot)
contains 'snapshot declares control-plane component' "$SNAPSHOT" '"component":"vegas-control-plane"'
contains 'snapshot declares read-only mode' "$SNAPSHOT" '"read_only":true'
contains 'snapshot declares simulation-only mode' "$SNAPSHOT" '"simulation_only":true'
contains 'snapshot includes evidence stage' "$SNAPSHOT" '"evidence":{'
contains 'snapshot includes analysis stage' "$SNAPSHOT" '"analysis":{'
contains 'snapshot includes policy stage' "$SNAPSHOT" '"policy":{'
contains 'snapshot includes action gate stage' "$SNAPSHOT" '"action_gate":{'
contains 'snapshot includes plugin stage' "$SNAPSHOT" '"plugins":{'
contains 'snapshot includes explicit no-write safety state' "$SNAPSHOT" '"hardware_writes":false'
contains 'snapshot includes explicit real action boundary' "$SNAPSHOT" '"real_action_layer":"NOT_IMPLEMENTED"'
contains 'snapshot excludes executed action' "$SNAPSHOT" '"executed":false'
contains 'snapshot excludes hardware changes' "$SNAPSHOT" '"hardware_changed":false'
contains 'snapshot bounds its audit records' "$SNAPSHOT" '"maximum":16'

REPEAT=$(run_control "$GOOD" snapshot)
SNAPSHOT_STABLE=$(printf '%s' "$SNAPSHOT" | sed 's/"generated_at":"[^"]*"/"generated_at":"TIMESTAMP"/g; s/,"system":.*$//')
REPEAT_STABLE=$(printf '%s' "$REPEAT" | sed 's/"generated_at":"[^"]*"/"generated_at":"TIMESTAMP"/g; s/,"system":.*$//')
[ "$SNAPSHOT_STABLE" = "$REPEAT_STABLE" ] && ok 'fixed control-plane schema, operation, lifecycle, and safety header are deterministic outside source timestamps' || not_ok 'fixed control-plane schema, operation, lifecycle, and safety header are deterministic outside source timestamps'

UNKNOWN_SNAPSHOT=$(run_control "$UNKNOWN" snapshot)
contains 'unknown evidence fails closed to blocked lifecycle' "$UNKNOWN_SNAPSHOT" '"lifecycle":"BLOCKED"'
contains 'unknown evidence preserves conservative recommendation' "$UNKNOWN_SNAPSHOT" '"value":"remain_conservative"'
contains 'unknown evidence preserves unavailable evidence stage' "$UNKNOWN_SNAPSHOT" '"availability":"UNAVAILABLE"'

EVALUATED=$(run_control "$GOOD" evaluate)
contains 'evaluate emits a control-plane snapshot' "$EVALUATED" '"component":"vegas-control-plane"'
[ ! -e "$AUDIT/simulation-audit.log" ] && ok 'evaluate does not append Action Safety Gate audit' || not_ok 'evaluate does not append Action Safety Gate audit'

SIMULATED=$(run_control "$GOOD" simulate)
contains 'simulate retains simulation-only safety boundary' "$SIMULATED" '"simulation_only":true'
contains 'simulate does not execute an action' "$SIMULATED" '"executed":false'
contains 'simulate does not change hardware' "$SIMULATED" '"hardware_changed":false'
[ -f "$AUDIT/simulation-audit.log" ] && ok 'simulate delegates only to bounded Action Safety Gate audit' || not_ok 'simulate delegates only to bounded Action Safety Gate audit'
[ ! -e "$RUNTIME/managed-state" ] && ok 'simulate does not create a managed action state' || not_ok 'simulate does not create a managed action state'

I=1
while [ "$I" -le 20 ]; do run_control "$GOOD" simulate >/dev/null; I=$((I + 1)); done
COUNT=$(awk 'END { print NR + 0 }' "$AUDIT/simulation-audit.log" 2>/dev/null)
[ "$COUNT" -le 16 ] && ok 'simulation audit remains bounded to sixteen records' || not_ok 'simulation audit remains bounded to sixteen records'
not_contains 'simulation audit excludes device action records' "$(cat "$AUDIT/simulation-audit.log")" 'hardware_changed=YES'
not_contains 'simulation audit excludes credentials' "$(cat "$AUDIT/simulation-audit.log")" 'credential='

fails 'unknown direct control-plane operation is rejected' run_control "$GOOD" apply
fails 'extra direct control-plane argument is rejected' run_control "$GOOD" simulate gpu_governor
fails 'path-like direct control-plane input is rejected' run_control "$GOOD" ../../outside

VEGAS_CONTROL=$(run_vegas "$GOOD" control snapshot)
contains 'VEGAS control route exposes fixed envelope' "$VEGAS_CONTROL" '"component":"vegas-control-plane"'
fails 'VEGAS control route rejects an apply operation' sh "$VEGAS" control apply
PLUGIN_CONTROL=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_CONTROL_PLANE_RUNTIME_DIR="$RUNTIME" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$MANAGER" invoke ax-t615-game-optimizer control status)
contains 'AX-T615 plugin manager control route delegates to fixed control plane' "$PLUGIN_CONTROL" 'VEGAS CONTROL PLANE'
fails 'plugin manager rejects arbitrary control-plane input' sh "$MANAGER" invoke ax-t615-game-optimizer control ../../outside

UNIFIED=$(run_vegas "$GOOD" snapshot)
contains 'unified VEGAS snapshot includes control-plane envelope' "$UNIFIED" '"control_plane":{"schema":"1","component":"vegas-control-plane"'
DASH=$(ORCH_EVIDENCE_FILE="$GOOD" VEGAS_CONTROL_PLANE_RUNTIME_DIR="$RUNTIME" VEGAS_ACTION_GATE_RUNTIME_DIR="$AUDIT" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot includes control-plane envelope' "$DASH" '"control_plane":{"schema":"1","component":"vegas-control-plane"'
for ID in controlPlaneState controlPlaneReason controlPlaneLifecycle controlPlaneRecommendation controlPlaneConfidence controlPlaneEvidenceQuality controlPlaneEvidenceStage controlPlaneAnalysisStage controlPlanePolicyStage controlPlaneActionGateStage controlPlanePluginsStage controlPlaneSimulation controlPlaneExecuted controlPlaneHardwareChanged controlPlaneAuditCount controlPlaneAuditBound controlPlaneProvenance; do
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard binds $ID with text renderer" || not_ok "dashboard binds $ID with text renderer"
done
grep -F 'id="control-plane"' "$DASHBOARD_HTML" >/dev/null 2>&1 && ok 'dashboard contains non-interactive Control Plane panel' || not_ok 'dashboard contains non-interactive Control Plane panel'

SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
run_control "$GOOD" evaluate >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'control-plane evaluation preserves System Observer isolation' || not_ok 'control-plane evaluation preserves System Observer isolation'

contains 'tests use repository-local temporary directory' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'control plane contains no hard-coded temporary directory' "$(grep -n '/tmp/' "$CONTROL" 2>/dev/null || :)" '/tmp/'
for TARGET in "$CONTROL" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$PLUGIN" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$CONTROL" >/dev/null 2>&1 && not_ok 'control plane excludes unsafe control and network primitives' || ok 'control plane excludes unsafe control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'CONTROL_PLANE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
