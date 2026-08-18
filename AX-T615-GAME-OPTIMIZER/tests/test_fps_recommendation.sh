#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"; F60="$FIXTURE_DIR/fps/stable-60"
recommend() { FPS_DATA_ROOT="$F60" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" FPS_THERMAL_STATE="${1:-NORMAL}" FPS_MEMORY_STATE="${2:-NORMAL}" FPS_GPU_STATE="${3:-UNKNOWN}" FPS_CPU_STATE=UNKNOWN sh "$BIN_DIR/fps-controller" recommend; }
O="$(recommend NORMAL NORMAL UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: BALANCED' 'normal balanced recommendation'
O="$(recommend CAUTION NORMAL UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: CONSERVATIVE' 'caution conservative recommendation'
O="$(recommend THROTTLED NORMAL UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: CONSERVATIVE' 'throttled conservative recommendation'
O="$(recommend CRITICAL NORMAL UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: PERFORMANCE_BLOCKED' 'critical thermal block'
O="$(recommend NORMAL PRESSURE UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: BALANCED' 'memory pressure balanced recommendation'
O="$(recommend NORMAL HIGH_PRESSURE UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: CONSERVATIVE' 'high memory conservative recommendation'
O="$(recommend NORMAL CRITICAL UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: PERFORMANCE_BLOCKED' 'critical memory block'
O="$(recommend UNKNOWN UNKNOWN UNKNOWN)"; step8_assert_contains "$O" 'Recommendation: CONSERVATIVE' 'unknown fail-safe recommendation'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/fps/missing-data" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" FPS_THERMAL_STATE=NORMAL FPS_MEMORY_STATE=NORMAL sh "$BIN_DIR/fps-controller" recommend)"; step8_assert_contains "$O" 'Recommendation: UNKNOWN' 'unavailable data recommendation'
step8_pass 'FPS recommendation and thermal/memory/GPU-safe coordination'
step8_cleanup
