#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"
for CASE in stable variable spiky severe; do
    F="$FIXTURE_DIR/frame-time/$CASE"
    O="$(FPS_DATA_ROOT="$F" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"
    step8_assert_contains "$O" 'Average frame-time:' "$CASE average frame-time"
    step8_assert_contains "$O" 'Minimum frame-time:' "$CASE minimum frame-time"
    step8_assert_contains "$O" 'Maximum frame-time:' "$CASE maximum frame-time"
    step8_assert_contains "$O" 'Frame-time P50:' "$CASE p50"
    step8_assert_contains "$O" 'Frame-time P90:' "$CASE p90"
    step8_assert_contains "$O" 'Frame-time P95:' "$CASE p95"
    step8_assert_contains "$O" 'Frame-time P99:' "$CASE p99"
    step8_assert_contains "$O" 'FPS source: DERIVED' "$CASE derived FPS label"
done
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/frame-time/spiky" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Frame-time spikes:' 'frame-time spike output'; step8_assert_contains "$O" 'Largest spike: 52.00 ms' 'largest frame-time spike'
step8_pass 'frame-time averages, percentiles, derived FPS, and spike reporting'
step8_cleanup
