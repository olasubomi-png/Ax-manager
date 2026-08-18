#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"; F60="$FIXTURE_DIR/fps/stable-60"; FJ="$FIXTURE_DIR/fps/unstable-60"
analyze() { FPS_DATA_ROOT="$1" DISPLAY_DATA_ROOT="$2" FPS_LOG_FILE="$TMP_ROOT/fps.log" PERFORMANCE_ANALYZER_THERMAL_STATE="${3:-NORMAL}" PERFORMANCE_ANALYZER_MEMORY_STATE="${4:-NORMAL}" PERFORMANCE_ANALYZER_GPU_UTILIZATION="${5:-}" PERFORMANCE_ANALYZER_CPU_UTILIZATION="${6:-}" FPS_GPU_STATE=UNKNOWN FPS_CPU_STATE=UNKNOWN sh "$BIN_DIR/performance-analyzer"; }
O="$(analyze "$F60" "$D60" NORMAL NORMAL 98 '')"; step8_assert_contains "$O" 'Bottleneck: LIKELY_GPU_PRESSURE' 'GPU bottleneck'; step8_assert_contains "$O" 'Confidence: HIGH' 'GPU confidence'
O="$(analyze "$F60" "$D60" NORMAL NORMAL '' 96)"; step8_assert_contains "$O" 'Bottleneck: LIKELY_CPU_PRESSURE' 'CPU bottleneck'; step8_assert_contains "$O" 'Confidence: HIGH' 'CPU confidence'
O="$(analyze "$F60" "$D60" CRITICAL NORMAL '' '')"; step8_assert_contains "$O" 'Bottleneck: LIKELY_THERMAL_LIMIT' 'thermal bottleneck'; step8_assert_contains "$O" 'Confidence: HIGH' 'thermal confidence'
O="$(analyze "$F60" "$D60" NORMAL CRITICAL '' '')"; step8_assert_contains "$O" 'Bottleneck: LIKELY_MEMORY_PRESSURE' 'memory bottleneck'; step8_assert_contains "$O" 'Confidence: HIGH' 'memory confidence'
O="$(analyze "$FJ" "$D60" NORMAL NORMAL '' '')"; step8_assert_contains "$O" 'Bottleneck: LIKELY_FRAME_PACING' 'frame-pacing bottleneck'; step8_assert_contains "$O" 'Confidence: MEDIUM' 'pacing confidence'
O="$(analyze "$F60" "$FIXTURE_DIR/display/unknown-refresh" NORMAL NORMAL '' '')"; step8_assert_contains "$O" 'Bottleneck: UNKNOWN' 'unknown display evidence'
O="$(FPS_DATA_ROOT="$F60" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" PERFORMANCE_ANALYZER_THERMAL_STATE=NORMAL PERFORMANCE_ANALYZER_MEMORY_STATE=NORMAL PERFORMANCE_ANALYZER_GPU_UTILIZATION='' PERFORMANCE_ANALYZER_CPU_UTILIZATION='' FPS_GPU_STATE=UNKNOWN FPS_CPU_STATE=UNKNOWN sh "$BIN_DIR/performance-analyzer")"; step8_assert_contains "$O" 'Confidence:' 'confidence always reported'; step8_assert_contains "$O" 'No CPU, GPU, thermal, memory, display' 'analyzer read-only marker'
step8_pass 'GPU, CPU, thermal, memory, frame-pacing, display, unknown, and confidence analysis'
step8_cleanup
