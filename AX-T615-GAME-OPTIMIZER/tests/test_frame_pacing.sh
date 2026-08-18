#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/frame-time/stable" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Frame pacing: STABLE' 'stable frame pacing'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/frame-time/variable" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Frame pacing: UNSTABLE' 'variable data is unstable'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/frame-time/spiky" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Frame pacing: UNSTABLE' 'spiky data is unstable'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/fps/missing-data" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Frame pacing: UNKNOWN' 'unknown pacing'
step8_pass 'stable, variable, unstable, and unknown frame-pacing classifications'
step8_cleanup
