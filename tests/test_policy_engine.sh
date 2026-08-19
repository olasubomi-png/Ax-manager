#!/usr/bin/env sh
# Phase 8 contract: deterministic, recommendation-only policy with a fixed no-action boundary.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/bin/policy-engine"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
PLUGIN_META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
TMP="${POLICY_TEST_TMP:-$ROOT/tests/.tmp/policy-engine-$$}"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/plugin.json" ] && cp "$TMP/plugin.json" "$PLUGIN_META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP/history" || exit 1
cp "$PLUGIN_META" "$TMP/plugin.json"

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }

reset_history() { rm -rf "$TMP/history" && mkdir -p "$TMP/history"; }

write_fixture() {
    FILE=$1 CPU=$2 GPU=$3 MEMORY=$4 THERMAL=$5 FPS=$6 PACING=$7 BATTERY=$8 POWER=$9 PROFILE=${10} AGE=${11}
    cat > "$FILE" <<EOF
CPU_UTILIZATION=$CPU
CPU_STATE=NORMAL
GPU_UTILIZATION=$GPU
GPU_STATE=NORMAL
MEMORY_USAGE_PERCENT=$MEMORY
MEMORY_AVAILABLE_MB=1200
MEMORY_STATE=NORMAL
THERMAL_TEMP_C=38
THERMAL_STATE=$THERMAL
THERMAL_TREND=STABLE
FPS=$FPS
FRAME_TIME_MS=16.7
FRAME_PACING=$PACING
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
SESSION_ID=policy-test-session
SESSION_STATUS=ACTIVE
EOF
}

evaluate() {
    ORCH_EVIDENCE_FILE="$1" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot
}

reset_history
cat > "$TMP/unknown.txt" <<'EOF'
THERMAL_STATE=UNKNOWN
BATTERY_PERCENT=UNKNOWN
BATTERY_HEALTH=UNKNOWN
POWER_STATE=UNKNOWN
EVIDENCE_AGE_SECONDS=10
EOF
UNKNOWN=$(evaluate "$TMP/unknown.txt")
contains 'unknown safety evidence uses insufficient policy' "$UNKNOWN" '"policy_state":"INSUFFICIENT_EVIDENCE"'
contains 'unknown safety evidence remains conservative' "$UNKNOWN" '"recommendation":"remain_conservative"'
contains 'unknown evidence has safety priority' "$UNKNOWN" '"priority":"SAFETY"'
contains 'unknown evidence blocks automatic action' "$UNKNOWN" '"rejected_options":"performance_advisory,profile_preference,automatic_action"'

reset_history
write_fixture "$TMP/thermal.txt" 95 95 95 HOT 30 UNSTABLE 10 LOW_POWER PERFORMANCE 10
THERMAL=$(evaluate "$TMP/thermal.txt")
contains 'thermal protection has policy precedence' "$THERMAL" '"policy_state":"SAFETY_BLOCKED"'
contains 'thermal protection recommends cool profile only' "$THERMAL" '"recommendation":"consider_cool_profile"'
contains 'thermal protection retains high confidence' "$THERMAL" '"priority":"THERMAL"'
contains 'thermal policy never exposes action layer' "$THERMAL" '"action_layer":"NOT_IMPLEMENTED"'

reset_history
write_fixture "$TMP/memory.txt" 35 35 95 NORMAL 60 STABLE 68 NORMAL BALANCED 10
MEMORY=$(evaluate "$TMP/memory.txt")
contains 'memory safety block is deterministic' "$MEMORY" '"policy_state":"SAFETY_BLOCKED"'
contains 'memory safety block recommends inspection' "$MEMORY" '"recommendation":"inspect_memory_pressure"'
contains 'memory safety has memory priority' "$MEMORY" '"priority":"MEMORY"'

reset_history
write_fixture "$TMP/power.txt" 35 35 55 NORMAL 60 STABLE 10 LOW_POWER PERFORMANCE 10
POWER=$(evaluate "$TMP/power.txt")
contains 'power protection receives battery advisory' "$POWER" '"policy_state":"BATTERY_ADVISORY"'
contains 'power protection recommends battery profile' "$POWER" '"recommendation":"consider_battery_profile"'
contains 'power protection has power priority' "$POWER" '"priority":"POWER"'

reset_history
write_fixture "$TMP/pacing.txt" 35 35 55 NORMAL 60 UNSTABLE 68 NORMAL BALANCED 10
PACING=$(evaluate "$TMP/pacing.txt")
contains 'frame pacing becomes balanced advisory' "$PACING" '"policy_state":"BALANCED"'
contains 'frame pacing requests observation' "$PACING" '"recommendation":"inspect_frame_pacing"'

reset_history
write_fixture "$TMP/cool.txt" 35 35 55 NORMAL 60 STABLE 68 NORMAL COOL 10
COOL=$(evaluate "$TMP/cool.txt")
contains 'cool profile is respected after safety checks' "$COOL" '"policy_state":"COOL_ADVISORY"'
contains 'cool profile retains current policy' "$COOL" '"recommendation":"retain_current_profile"'
contains 'profile cannot enable automatic action' "$COOL" '"rejected_options":"automatic_action,profile_override"'

reset_history
write_fixture "$TMP/gpu.txt" 35 95 55 NORMAL 30 STABLE 68 NORMAL PERFORMANCE 10
I=1
while [ "$I" -le 4 ]; do evaluate "$TMP/gpu.txt" >/dev/null || exit 1; I=$((I + 1)); done
GPU=$(evaluate "$TMP/gpu.txt")
contains 'stable validated GPU pressure is performance advisory' "$GPU" '"policy_state":"PERFORMANCE_ADVISORY"'
contains 'GPU policy stays recommendation-only' "$GPU" '"recommendation":"consider_performance_profile"'
contains 'GPU advisory receives performance priority' "$GPU" '"priority":"PERFORMANCE"'
contains 'GPU advisory reports bounded hysteresis input' "$GPU" '"stable_samples_required":3'

reset_history
write_fixture "$TMP/safe.txt" 35 35 55 NORMAL 60 STABLE 68 NORMAL BALANCED 10
SAFE=$(evaluate "$TMP/safe.txt")
contains 'safe no-clear evidence remains monitor-only' "$SAFE" '"policy_state":"SAFE"'
contains 'safe no-clear evidence continues monitoring' "$SAFE" '"recommendation":"continue_monitoring"'

STALE_FILE="$TMP/stale.txt"
write_fixture "$STALE_FILE" 95 95 95 HOT 30 UNSTABLE 10 LOW_POWER PERFORMANCE 999
STALE=$(evaluate "$STALE_FILE")
contains 'stale telemetry does not bypass conservative fallback' "$STALE" '"policy_state":"INSUFFICIENT_EVIDENCE"'
contains 'stale telemetry is low confidence' "$STALE" '"confidence":"LOW"'

STATUS=$(ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" status)
contains 'policy status identifies recommendation engine' "$STATUS" 'VEGAS-INJECT POLICY & RECOMMENDATIONS'
contains 'policy status declares no action layer' "$STATUS" 'Action layer: NOT_IMPLEMENTED'
CAPS=$(sh "$ENGINE" capabilities)
contains 'policy capabilities use fixed operation set' "$CAPS" 'POLICY_ENGINE_CAPABILITIES=status,evaluate,snapshot,capabilities'
contains 'policy capabilities declare read-only operation' "$CAPS" 'HARDWARE_WRITES=NO'
fails 'policy engine rejects arbitrary operation' sh "$ENGINE" arbitrary-operation
fails 'VEGAS rejects arbitrary policy operation' sh "$VEGAS" policy ../../outside
fails 'plugin manager rejects arbitrary policy operation' sh "$MANAGER" invoke ax-t615-game-optimizer policy ../../outside

VEGAS_POLICY=$(ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" policy snapshot)
contains 'VEGAS fixed policy route returns policy output' "$VEGAS_POLICY" 'vegas-inject-policy-engine-read-only'
PLUGIN_POLICY=$(ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$MANAGER" invoke ax-t615-game-optimizer policy snapshot)
contains 'AX-T615 fixed policy route remains isolated' "$PLUGIN_POLICY" 'vegas-inject-policy-engine-read-only'
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" policy snapshot >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'policy preserves System Observer isolation' || not_ok 'policy preserves System Observer isolation'

UNIFIED=$(ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" snapshot)
contains 'unified snapshot includes policy envelope' "$UNIFIED" '"policy":{"schema":"1"'
contains 'unified policy envelope remains advisory' "$UNIFIED" '"action_layer":"NOT_IMPLEMENTED"'
DASH=$(ORCH_EVIDENCE_FILE="$TMP/safe.txt" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot includes policy envelope' "$DASH" '"policy":{"schema":"1"'
for ID in policyState policyRecommendation policyConfidence policyPriority policyReason policyEvidenceQuality policyBottleneck policySafetyClassification policyRejectedOptions policyProvenance policyTimestamp policyHistoryCount; do
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard renders $ID text-safely" || not_ok "dashboard renders $ID text-safely"
done

printf '%s\n' '{"id":"ax-t615-game-optimizer","name":"AX-T615 Game Optimizer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":true,"hardware_writes":false,"exec":"do-not-run","minimum_app_version":"1.0.0"}' > "$PLUGIN_META"
INVALID_META=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains 'unsafe executable metadata remains rejected' "$INVALID_META" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED'
cp "$TMP/plugin.json" "$PLUGIN_META"

contains 'tests use repository-local temporary directory' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'policy engine contains no hard-coded temp directory' "$(grep -n '/tmp/' "$ENGINE" 2>/dev/null || :)" '/tmp/'
for TARGET in "$ENGINE" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$ENGINE" >/dev/null 2>&1 && not_ok 'policy engine excludes unsafe control and network primitives' || ok 'policy engine excludes unsafe control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'PHASE8_POLICY_ENGINE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
