#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
PROFILES="$STEP9_ROOT/config/game-profiles"
run_case() { CASE_NAME="$1" THERMAL="$2" MEMORY="$3"; OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/$CASE_NAME" GAME_PROFILE_DIR="$PROFILES" GAME_PROFILE_THERMAL_STATE="$THERMAL" GAME_PROFILE_MEMORY_STATE="$MEMORY" GAME_PROFILE_GPU_STATE=UNKNOWN GAME_PROFILE_CPU_STATE=UNKNOWN sh "$STEP9_BIN/game-profile" recommend performance)"; printf '%s\n' "$OUT"; }
OUT="$(run_case normal NORMAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE' 'normal telemetry preserves performance profile'
OUT="$(run_case caution CAUTION NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: BALANCED' 'thermal caution reduces performance profile'
OUT="$(run_case hot HOT NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: COOL' 'hot thermal state selects cool policy'
OUT="$(run_case critical CRITICAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE_BLOCKED' 'critical thermal state blocks performance'
OUT="$(run_case pressure NORMAL PRESSURE)"; step9_assert_contains "$OUT" 'Final recommendation: BALANCED' 'memory pressure limits performance profile'
OUT="$(run_case highpressure NORMAL HIGH_PRESSURE)"; step9_assert_contains "$OUT" 'Final recommendation: CONSERVATIVE' 'high memory pressure selects conservative policy'
OUT="$(run_case unknown UNKNOWN NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: CONSERVATIVE' 'unknown thermal state fails safe'
OUT="$(run_case unknownmemory NORMAL UNKNOWN)"; step9_assert_contains "$OUT" 'Final recommendation: CONSERVATIVE' 'unknown memory state fails safe'
step9_assert_contains "$OUT" 'GPU: UNKNOWN' 'unknown GPU is reported without fabrication'
step9_assert_contains "$OUT" 'CPU: UNKNOWN' 'unknown CPU is reported without fabrication'
step9_assert_contains "$OUT" 'No hardware settings were changed.' 'recommendation is data-only'
