#!/usr/bin/env sh
# Performance Observer: fixed read-only VEGAS-inject adapter. It normalizes only repository-owned telemetry evidence and never controls hardware.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
APP_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
DEFAULT_AXGO_ROOT="$APP_ROOT/AX-T615-GAME-OPTIMIZER"
AXGO_ROOT="${AXGO_ROOT:-$DEFAULT_AXGO_ROOT}"

# The only callable telemetry adapter is the repository-owned AX-T615 evidence normalizer.
[ "$AXGO_ROOT" = "$DEFAULT_AXGO_ROOT" ] || AXGO_ROOT="$DEFAULT_AXGO_ROOT"

usage() {
    cat <<'EOF'
Usage: performance-observer {status|capabilities|inspect|snapshot}

Performance Observer exposes fixed, normalized performance evidence from existing
read-only VEGAS-inject sources. Missing evidence is reported as UNKNOWN.
EOF
}

json_escape() {
    printf '%s' "$1" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

value() {
    KEY="$1"
    DATA="$2"
    RESULT=$(printf '%s\n' "$DATA" | awk -F= -v key="$KEY" '$1 == key { value=$0; sub(/^[^=]*=/, "", value); print value }' | tail -n 1)
    [ -n "$RESULT" ] && printf '%s' "$RESULT" || printf '%s' 'UNKNOWN'
}

evidence() {
    EVIDENCE_ADAPTER="$AXGO_ROOT/bin/orchestrator-evidence"
    [ -r "$EVIDENCE_ADAPTER" ] || return 0
    ORCH_EVIDENCE_FILE="${ORCH_EVIDENCE_FILE:-}" AXGO_ROOT="$AXGO_ROOT" AXGO_DATA_ROOT="$AXGO_ROOT" sh "$EVIDENCE_ADAPTER" 2>/dev/null || :
}

status() {
    printf 'PLUGIN_ID=performance-observer\n'
    printf 'PLUGIN_NAME=Performance Observer\n'
    printf 'PLUGIN_STATUS=AVAILABLE\n'
    printf 'ENABLED=YES\n'
    printf 'LIFECYCLE=ENABLED\n'
    printf 'READ_ONLY=YES\n'
    printf 'HARDWARE_WRITES=NO\n'
    printf 'OPERATIONS=status,capabilities,inspect,snapshot\n'
    printf 'EVIDENCE_SOURCES=AX-T615_ORCHESTRATOR_EVIDENCE\n'
    printf 'SAFETY_CLASSIFICATION=READ_ONLY_OBSERVABILITY\n'
    printf 'FORBIDDEN_ACTIONS_BLOCKED=YES\n'
}

capabilities() {
    printf 'PLUGIN_ID=performance-observer\n'
    printf 'CAPABILITIES=status,capabilities,inspect,snapshot\n'
    printf 'OBSERVATION_CAPABILITIES=read_cpu,read_gpu,read_memory,read_thermal,read_fps,read_battery,read_power\n'
    printf 'EVIDENCE_CATEGORIES=cpu,gpu,memory,thermal,fps,battery,power\n'
    printf 'READ_ONLY=YES\n'
    printf 'HARDWARE_WRITES=NO\n'
    printf 'FORBIDDEN_ACTIONS_BLOCKED=YES\n'
}

inspect() {
    status
    printf 'PLUGIN_VERSION=1.0.0\n'
    printf 'SUPPORTED_OPERATIONS=status,capabilities,inspect,snapshot\n'
    printf 'SUPPORTED_EVIDENCE=cpu,gpu,memory,thermal,fps,battery,power\n'
    printf 'DERIVED_VALUES=NONE\n'
    printf 'UNAVAILABLE_TELEMETRY=UNKNOWN\n'
}

snapshot() {
    DATA=$(evidence)
    CPU_UTILIZATION=$(value CPU_UTILIZATION "$DATA")
    CPU_STATE=$(value CPU_STATE "$DATA")
    GPU_UTILIZATION=$(value GPU_UTILIZATION "$DATA")
    GPU_STATE=$(value GPU_STATE "$DATA")
    MEMORY_USAGE_PERCENT=$(value MEMORY_USAGE_PERCENT "$DATA")
    MEMORY_AVAILABLE_MB=$(value MEMORY_AVAILABLE_MB "$DATA")
    MEMORY_STATE=$(value MEMORY_STATE "$DATA")
    THERMAL_TEMP_C=$(value THERMAL_TEMP_C "$DATA")
    THERMAL_PEAK_C=$(value THERMAL_PEAK_C "$DATA")
    THERMAL_STATE=$(value THERMAL_STATE "$DATA")
    THERMAL_TREND=$(value THERMAL_TREND "$DATA")
    FPS=$(value FPS "$DATA")
    FRAME_TIME_MS=$(value FRAME_TIME_MS "$DATA")
    FRAME_PACING=$(value FRAME_PACING "$DATA")
    FPS_TREND=$(value FPS_TREND "$DATA")
    BATTERY_PERCENT=$(value BATTERY_PERCENT "$DATA")
    CHARGING_STATE=$(value CHARGING_STATE "$DATA")
    BATTERY_TEMP_C=$(value BATTERY_TEMP_C "$DATA")
    BATTERY_HEALTH=$(value BATTERY_HEALTH "$DATA")
    VOLTAGE_MV=$(value VOLTAGE_MV "$DATA")
    CURRENT_MA=$(value CURRENT_MA "$DATA")
    ESTIMATED_WATTS=$(value ESTIMATED_WATTS "$DATA")
    DRAIN_RATE=$(value DRAIN_RATE "$DATA")
    POWER_STATE=$(value POWER_STATE "$DATA")

    printf '{'
    printf '"schema":"1",'
    printf '"source":"performance-observer-read-only",'
    printf '"read_only":true,'
    printf '"plugin":{"id":"performance-observer","name":"Performance Observer","lifecycle":"ENABLED","status":"AVAILABLE"},'
    printf '"evidence":{'
    printf '"cpu":{"utilization":"%s","state":"%s"},' "$(json_escape "$CPU_UTILIZATION")" "$(json_escape "$CPU_STATE")"
    printf '"gpu":{"utilization":"%s","state":"%s"},' "$(json_escape "$GPU_UTILIZATION")" "$(json_escape "$GPU_STATE")"
    printf '"memory":{"usage_percent":"%s","available_mb":"%s","state":"%s"},' "$(json_escape "$MEMORY_USAGE_PERCENT")" "$(json_escape "$MEMORY_AVAILABLE_MB")" "$(json_escape "$MEMORY_STATE")"
    printf '"thermal":{"temperature_c":"%s","peak_c":"%s","state":"%s","trend":"%s"},' "$(json_escape "$THERMAL_TEMP_C")" "$(json_escape "$THERMAL_PEAK_C")" "$(json_escape "$THERMAL_STATE")" "$(json_escape "$THERMAL_TREND")"
    printf '"fps":{"value":"%s","frame_time_ms":"%s","frame_pacing":"%s","trend":"%s"},' "$(json_escape "$FPS")" "$(json_escape "$FRAME_TIME_MS")" "$(json_escape "$FRAME_PACING")" "$(json_escape "$FPS_TREND")"
    printf '"battery":{"percent":"%s","charging":"%s","temperature_c":"%s","health":"%s"},' "$(json_escape "$BATTERY_PERCENT")" "$(json_escape "$CHARGING_STATE")" "$(json_escape "$BATTERY_TEMP_C")" "$(json_escape "$BATTERY_HEALTH")"
    printf '"power":{"voltage_mv":"%s","current_ma":"%s","estimated_watts":"%s","drain_rate":"%s","state":"%s"}' "$(json_escape "$VOLTAGE_MV")" "$(json_escape "$CURRENT_MA")" "$(json_escape "$ESTIMATED_WATTS")" "$(json_escape "$DRAIN_RATE")" "$(json_escape "$POWER_STATE")"
    printf '},'
    printf '"provenance":{"observed_telemetry":"AX-T615_ORCHESTRATOR_EVIDENCE","unavailable_telemetry":"UNKNOWN","derived_values":"NONE"},'
    printf '"safety":{"read_only":"YES","hardware_writes":"NO","forbidden_actions_blocked":"YES","network_access":"NOT_AVAILABLE","process_control":"NOT_AVAILABLE"}'
    printf '}\n'
}

case "${1:-help}" in
    status) status ;;
    capabilities) capabilities ;;
    inspect) inspect ;;
    snapshot) snapshot ;;
    help|-h|--help) usage ;;
    *) usage >&2; exit 2 ;;
esac
