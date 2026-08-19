#!/usr/bin/env sh
# Phase 6 contract: fixed, deterministic, repository-local evidence analysis only.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/bin/evidence-engine"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASH_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
TMP="$ROOT/tests/.tmp/evidence-engine"
PASS=0
FAIL=0

mkdir -p "$TMP" || exit 1
rm -f "$TMP"/*.env "$TMP"/*.out "$TMP"/history/* 2>/dev/null || :
mkdir -p "$TMP/history" || exit 1

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
command_fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }

write_fixture() {
  FILE=$1
  THERMAL=$2
  MEMORY=$3
  FPS_VALUE=$4
  PACING=$5
  BATTERY=$6
  POWER=$7
  AGE=$8
  cat > "$FILE" <<EOF
CPU_UTILIZATION=41
CPU_STATE=NORMAL
GPU_UTILIZATION=37
GPU_STATE=NORMAL
MEMORY_USAGE_PERCENT=$MEMORY
MEMORY_AVAILABLE_MB=1200
MEMORY_STATE=NORMAL
THERMAL_TEMP_C=$THERMAL
THERMAL_STATE=NORMAL
THERMAL_TREND=STABLE
FPS=$FPS_VALUE
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
DISPLAY_REFRESH_HZ=60
EOF
}

write_fixture "$TMP/valid.env" 38 55 60 STABLE 68 NORMAL 12
VALID=$(ORCH_EVIDENCE_FILE="$TMP/valid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "valid snapshot declares schema" "$VALID" '"schema":"1"'
contains "valid snapshot is read-only" "$VALID" '"read_only":true'
contains "valid cpu is normalized" "$VALID" '"cpu_utilization"'
contains "valid cpu state is explicit" "$VALID" '"state":"VALID"'
contains "valid timestamp is present" "$VALID" '"timestamp":"'
contains "valid freshness is fresh" "$VALID" '"freshness":"FRESH"'
contains "valid provenance is present" "$VALID" 'AX-T615_ORCHESTRATOR_EVIDENCE'
contains "valid confidence is present" "$VALID" '"confidence":"HIGH"'
contains "valid metric validity is trusted" "$VALID" '"validity":"TRUSTED"'
contains "valid quality remains healthy" "$VALID" '"classification":"HEALTHY"'
contains "valid fallback is no" "$VALID" '"fallback_required":"NO"'
contains "valid history is privacy bounded" "$VALID" '"contains_personal_data":false'
contains "valid safety rejects hardware writes" "$VALID" '"hardware_writes":"NO"'
contains "valid safety rejects network operations" "$VALID" '"network_operations":"NO"'

cat > "$TMP/unknown.env" <<'EOF'
THERMAL_TEMP_C=UNKNOWN
THERMAL_STATE=UNKNOWN
BATTERY_PERCENT=UNKNOWN
BATTERY_HEALTH=UNKNOWN
POWER_STATE=UNKNOWN
EVIDENCE_AGE_SECONDS=10
EOF
UNKNOWN=$(ORCH_EVIDENCE_FILE="$TMP/unknown.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "unknown telemetry remains explicit" "$UNKNOWN" '"state":"UNKNOWN"'
contains "unknown telemetry has low confidence" "$UNKNOWN" '"confidence":"LOW"'
contains "unknown safety evidence uses conservative quality" "$UNKNOWN" '"classification":"UNSAFE_UNKNOWN"'
contains "unknown safety evidence requires fallback" "$UNKNOWN" '"fallback_required":"YES"'

write_fixture "$TMP/unavailable.env" UNAVAILABLE UNAVAILABLE UNAVAILABLE UNAVAILABLE UNAVAILABLE UNAVAILABLE 10
UNAVAILABLE=$(ORCH_EVIDENCE_FILE="$TMP/unavailable.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "unavailable telemetry remains explicit" "$UNAVAILABLE" '"state":"UNAVAILABLE"'
contains "unavailable telemetry is not observed" "$UNAVAILABLE" '"validity":"NOT_OBSERVED"'

write_fixture "$TMP/stale.env" 38 55 60 STABLE 68 NORMAL 999
STALE=$(ORCH_EVIDENCE_FILE="$TMP/stale.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "stale telemetry freshness is explicit" "$STALE" '"freshness":"STALE"'
contains "stale telemetry state is explicit" "$STALE" '"state":"STALE"'
contains "stale telemetry requires fallback" "$STALE" '"fallback_required":"YES"'

write_fixture "$TMP/invalid.env" invalid 55 60 STABLE 68 NORMAL 10
INVALID=$(ORCH_EVIDENCE_FILE="$TMP/invalid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "invalid telemetry state is explicit" "$INVALID" '"state":"INVALID"'
contains "invalid telemetry is rejected" "$INVALID" '"validity":"REJECTED"'
contains "invalid telemetry requires fallback" "$INVALID" '"fallback_required":"YES"'

write_fixture "$TMP/conditions.env" 50 95 30 JANKY 10 CRITICAL 10
CONDITIONS=$(ORCH_EVIDENCE_FILE="$TMP/conditions.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "thermal escalation is detected" "$CONDITIONS" 'THERMAL_ESCALATION'
contains "memory pressure is detected" "$CONDITIONS" 'MEMORY_PRESSURE'
contains "fps instability is detected" "$CONDITIONS" 'FPS_INSTABILITY'
contains "frame pacing degradation is detected" "$CONDITIONS" 'FRAME_PACING_DEGRADATION'
contains "battery power anomaly is detected" "$CONDITIONS" 'BATTERY_POWER_ANOMALY'
contains "condition evidence is degraded" "$CONDITIONS" '"classification":"DEGRADED"'

rm -rf "$TMP/history" && mkdir -p "$TMP/history"
i=1
while [ "$i" -le 9 ]; do
  write_fixture "$TMP/history.env" 38 55 "$((50 + i))" STABLE 68 NORMAL 10
  ORCH_EVIDENCE_FILE="$TMP/history.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot >/dev/null || exit 1
  i=$((i + 1))
done
HISTORY=$(ORCH_EVIDENCE_FILE="$TMP/history.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" snapshot)
contains "history retains only its fixed bound" "$HISTORY" '"retained_samples":8'
contains "history exposes deterministic trend" "$HISTORY" '"fps":"RISING"'
HISTORY_STATUS=$(VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$ENGINE" history)
contains "history command reports fixed limit" "$HISTORY_STATUS" 'HISTORY_LIMIT=8'
contains "history command declares no personal data" "$HISTORY_STATUS" 'PERSONAL_DATA=NO'

ENGINE_STATUS=$(sh "$ENGINE" status)
contains "engine status is available" "$ENGINE_STATUS" 'STATUS=AVAILABLE'
contains "engine status declares read only" "$ENGINE_STATUS" 'READ_ONLY=YES'
ENGINE_CAPS=$(sh "$ENGINE" capabilities)
contains "engine capabilities list explicit states" "$ENGINE_CAPS" 'EVIDENCE_STATES=VALID,UNKNOWN,UNAVAILABLE,STALE,INVALID'
command_fails "engine rejects arbitrary operation" sh "$ENGINE" arbitrary-operation
command_fails "vegas rejects arbitrary evidence operation" sh "$VEGAS" evidence arbitrary-operation
VEGAS_EVIDENCE=$(ORCH_EVIDENCE_FILE="$TMP/valid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" evidence snapshot)
contains "vegas fixed evidence route returns engine snapshot" "$VEGAS_EVIDENCE" 'vegas-inject-evidence-engine-read-only'
PLUGIN_EVIDENCE=$(ORCH_EVIDENCE_FILE="$TMP/valid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$MANAGER" invoke ax-t615-game-optimizer evidence snapshot)
contains "fixed plugin evidence route is isolated" "$PLUGIN_EVIDENCE" 'vegas-inject-evidence-engine-read-only'
command_fails "plugin manager rejects arbitrary evidence path" sh "$MANAGER" invoke ax-t615-game-optimizer evidence ../../outside

UNIFIED=$(ORCH_EVIDENCE_FILE="$TMP/valid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$VEGAS" snapshot)
contains "unified snapshot preserves evidence engine envelope" "$UNIFIED" '"evidence_engine":'
contains "unified snapshot preserves legacy system envelope" "$UNIFIED" '"system":'
contains "unified snapshot preserves legacy performance envelope" "$UNIFIED" '"performance":'
DASH=$(ORCH_EVIDENCE_FILE="$TMP/valid.env" VEGAS_EVIDENCE_RUNTIME_DIR="$TMP/history" sh "$DASHBOARD" snapshot)
contains "dashboard snapshot includes evidence engine envelope" "$DASH" '"evidence_engine":'
contains "dashboard snapshot preserves old plugin envelopes" "$DASH" '"system_observer":'

for TARGET in "$ENGINE" "$ROOT/bin/vegas" "$ROOT/bin/plugin-manager" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh"; do
  grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su)[[:space:]]' "$ENGINE" >/dev/null 2>&1 && not_ok "engine excludes unsafe control primitives" || ok "engine excludes unsafe control primitives"
grep -F 'innerHTML' "$DASH_JS" >/dev/null 2>&1 && not_ok "dashboard excludes html injection sink" || ok "dashboard excludes html injection sink"
for ID in evidenceEngineQuality evidenceEngineFreshness evidenceEngineProvenance evidenceEngineConfidence evidenceEngineFallback evidenceTrendList; do
  grep -F "$ID" "$DASH_JS" >/dev/null 2>&1 && ok "dashboard renders $ID text-safely" || not_ok "dashboard renders $ID text-safely"
done

printf 'PHASE6_EVIDENCE_ENGINE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
