#!/usr/bin/env sh
# Phase 7 contract: deterministic, bounded, advisory bottleneck analysis only.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/bin/bottleneck-engine"
EVIDENCE_ENGINE="$ROOT/bin/evidence-engine"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
PLUGIN_META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
TMP="${BOTTLENECK_TEST_TMP:-$ROOT/tests/.tmp/bottleneck-engine-$$}"
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

write_fixture() {
    FILE=$1 CPU=$2 GPU=$3 MEMORY=$4 THERMAL_STATE=$5 FPS=$6 PACING=$7 BATTERY=$8 POWER=$9 DISPLAY=${10} AGE=${11}
    cat > "$FILE" <<EOF
CPU_UTILIZATION=$CPU
CPU_STATE=NORMAL
GPU_UTILIZATION=$GPU
GPU_STATE=NORMAL
MEMORY_USAGE_PERCENT=$MEMORY
MEMORY_AVAILABLE_MB=1200
MEMORY_STATE=NORMAL
THERMAL_TEMP_C=38
THERMAL_STATE=$THERMAL_STATE
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
DISPLAY_REFRESH_HZ=$DISPLAY
EOF
}

analyse() {
    ORCH_EVIDENCE_FILE="$1" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot
}

write_fixture "$TMP/cpu.env" 95 35 55 NORMAL 30 STABLE 68 NORMAL 120 10
CPU=$(analyse "$TMP/cpu.env")
contains 'CPU bottleneck detection' "$CPU" '"classification":"CPU_LIMITED"'
contains 'CPU bottleneck recommendation' "$CPU" '"recommended_observation":"inspect_cpu_pressure"'
contains 'CPU bottleneck is cautious before bounded history exists' "$CPU" '"confidence":"LOW"'

write_fixture "$TMP/gpu.env" 35 95 55 NORMAL 30 STABLE 68 NORMAL 120 10
GPU=$(analyse "$TMP/gpu.env")
contains 'GPU bottleneck detection' "$GPU" '"classification":"GPU_LIMITED"'
contains 'GPU bottleneck recommendation' "$GPU" '"recommended_observation":"inspect_gpu_pressure"'

write_fixture "$TMP/memory.env" 35 35 95 NORMAL 60 STABLE 68 NORMAL 120 10
MEMORY=$(analyse "$TMP/memory.env")
contains 'memory bottleneck detection' "$MEMORY" '"classification":"MEMORY_LIMITED"'
contains 'memory bottleneck recommendation' "$MEMORY" '"recommended_observation":"inspect_memory_pressure"'

write_fixture "$TMP/thermal.env" 35 35 55 HOT 60 STABLE 68 NORMAL 120 10
THERMAL=$(analyse "$TMP/thermal.env")
contains 'thermal bottleneck detection' "$THERMAL" '"classification":"THERMAL_LIMITED"'
contains 'thermal bottleneck recommendation' "$THERMAL" '"recommended_observation":"inspect_thermal_conditions"'

write_fixture "$TMP/power.env" 35 35 55 NORMAL 60 STABLE 68 LOW_POWER 120 10
POWER=$(analyse "$TMP/power.env")
contains 'power bottleneck detection' "$POWER" '"classification":"POWER_LIMITED"'
contains 'power bottleneck recommendation' "$POWER" '"recommended_observation":"inspect_power_conditions"'

write_fixture "$TMP/pacing.env" 35 35 55 NORMAL 60 UNSTABLE 68 NORMAL 120 10
PACING=$(analyse "$TMP/pacing.env")
contains 'frame-pacing bottleneck detection' "$PACING" '"classification":"FRAME_PACING_LIMITED"'
contains 'frame-pacing recommendation' "$PACING" '"recommended_observation":"inspect_frame_pacing"'

write_fixture "$TMP/display.env" 35 35 55 NORMAL 60 STABLE 68 NORMAL 60 10
DISPLAY=$(analyse "$TMP/display.env")
contains 'display limitation detection' "$DISPLAY" '"classification":"DISPLAY_LIMITED"'
contains 'display limitation recommendation' "$DISPLAY" '"recommended_observation":"verify_display_refresh"'

write_fixture "$TMP/mixed.env" 35 35 95 HOT 60 STABLE 68 NORMAL 120 10
MIXED=$(analyse "$TMP/mixed.env")
contains 'mixed bottleneck detection' "$MIXED" '"classification":"MIXED_BOTTLENECK"'
contains 'mixed bottleneck confidence' "$MIXED" '"confidence":"MEDIUM"'

write_fixture "$TMP/clear.env" 35 35 55 NORMAL 60 STABLE 68 NORMAL 120 10
CLEAR=$(analyse "$TMP/clear.env")
contains 'no clear bottleneck remains explicit' "$CLEAR" '"classification":"NO_CLEAR_BOTTLENECK"'
contains 'no clear bottleneck remains low confidence' "$CLEAR" '"confidence":"LOW"'

cat > "$TMP/unknown.env" <<'EOF'
THERMAL_TEMP_C=UNKNOWN
THERMAL_STATE=UNKNOWN
BATTERY_PERCENT=UNKNOWN
BATTERY_HEALTH=UNKNOWN
POWER_STATE=UNKNOWN
EVIDENCE_AGE_SECONDS=10
EOF
UNKNOWN=$(analyse "$TMP/unknown.env")
contains 'UNKNOWN evidence uses insufficient evidence classification' "$UNKNOWN" '"classification":"INSUFFICIENT_EVIDENCE"'
contains 'UNKNOWN evidence uses conservative fallback' "$UNKNOWN" '"recommended_observation":"remain_conservative"'
contains 'UNKNOWN evidence remains low confidence' "$UNKNOWN" '"confidence":"LOW"'

write_fixture "$TMP/stale.env" 95 35 55 NORMAL 30 STABLE 68 NORMAL 120 999
STALE=$(analyse "$TMP/stale.env")
contains 'STALE evidence remains insufficient' "$STALE" '"classification":"INSUFFICIENT_EVIDENCE"'
contains 'STALE evidence remains conservative' "$STALE" '"safety_classification":"READ_ONLY_CONSERVATIVE_FALLBACK"'

write_fixture "$TMP/invalid.env" invalid 35 55 NORMAL 30 STABLE 68 NORMAL 120 10
INVALID=$(analyse "$TMP/invalid.env")
contains 'INVALID evidence remains insufficient' "$INVALID" '"classification":"INSUFFICIENT_EVIDENCE"'
contains 'INVALID evidence remains low confidence' "$INVALID" '"confidence":"LOW"'

rm -rf "$TMP/history" && mkdir -p "$TMP/history"
I=1
while [ "$I" -le 9 ]; do
    write_fixture "$TMP/history.env" 95 35 55 NORMAL 30 STABLE 68 NORMAL 120 10
    analyse "$TMP/history.env" >/dev/null || exit 1
    I=$((I + 1))
done
HISTORY=$(analyse "$TMP/history.env")
contains 'analysis history is bounded' "$HISTORY" '"retained_samples":8'
contains 'analysis includes trend correlation' "$HISTORY" '"cpu_trend":'
FIRST=$(analyse "$TMP/history.env")
SECOND=$(analyse "$TMP/history.env")
contains 'analysis output remains deterministic in classification' "$FIRST" '"classification":"CPU_LIMITED"'
contains 'analysis output remains deterministic in recommendation' "$SECOND" '"recommended_observation":"inspect_cpu_pressure"'

STATUS=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" status)
contains 'engine status identifies analysis' "$STATUS" 'VEGAS-INJECT INTELLIGENT ANALYSIS'
contains 'engine status declares read-only operation' "$STATUS" 'Read-only: YES'
CAPS=$(sh "$ENGINE" capabilities)
contains 'engine capabilities are fixed' "$CAPS" 'BOTTLENECK_ENGINE_CAPABILITIES=status,analyze,snapshot,capabilities'
contains 'engine capabilities forbid hardware writes' "$CAPS" 'HARDWARE_WRITES=NO'
fails 'engine rejects arbitrary operation' sh "$ENGINE" arbitrary-operation
fails 'VEGAS rejects arbitrary analysis operation' sh "$VEGAS" analysis ../../outside
fails 'plugin manager rejects arbitrary analysis path' sh "$MANAGER" invoke ax-t615-game-optimizer analysis ../../outside

VEGAS_ANALYSIS=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" analysis snapshot)
contains 'VEGAS fixed analysis route returns the engine snapshot' "$VEGAS_ANALYSIS" 'vegas-inject-bottleneck-engine-read-only'
PLUGIN_ANALYSIS=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$MANAGER" invoke ax-t615-game-optimizer analysis snapshot)
contains 'AX-T615 fixed plugin analysis route is isolated' "$PLUGIN_ANALYSIS" 'vegas-inject-bottleneck-engine-read-only'
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" analysis snapshot >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && ok 'analysis preserves System Observer isolation' || not_ok 'analysis preserves System Observer isolation'
EVIDENCE=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$EVIDENCE_ENGINE" snapshot)
contains 'analysis consumes Phase 6 evidence output' "$EVIDENCE" 'vegas-inject-evidence-engine-read-only'

UNIFIED=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" snapshot)
contains 'unified snapshot includes an analysis envelope' "$UNIFIED" '"analysis":{"schema":"1"'
DASH=$(ORCH_EVIDENCE_FILE="$TMP/cpu.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot includes an analysis envelope' "$DASH" '"analysis":{"schema":"1"'
for ID in analysisClassification analysisConfidence analysisExplanation analysisSupportingEvidence analysisConflictingEvidence analysisEvidenceQuality analysisRecommendation analysisSafetyClassification analysisHistoryCount analysisTrendList; do
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard renders $ID text-safely" || not_ok "dashboard renders $ID text-safely"
done

printf '%s\n' '{"id":"ax-t615-game-optimizer","name":"AX-T615 Game Optimizer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":true,"hardware_writes":false,"exec":"do-not-run","minimum_app_version":"1.0.0"}' > "$PLUGIN_META"
INVALID_META=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains 'unsafe executable metadata is rejected' "$INVALID_META" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED'
cp "$TMP/plugin.json" "$PLUGIN_META"

contains 'tests use a repository-local temporary directory' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'engine contains no hard-coded /tmp dependency' "$(grep -n '/tmp/' "$ENGINE" 2>/dev/null || :)" '/tmp/'
for TARGET in "$ENGINE" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$ENGINE" >/dev/null 2>&1 && not_ok 'engine excludes unsafe control and network primitives' || ok 'engine excludes unsafe control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'PHASE7_BOTTLENECK_ENGINE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
