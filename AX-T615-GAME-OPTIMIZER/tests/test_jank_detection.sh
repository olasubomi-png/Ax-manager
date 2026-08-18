#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/fps/stable-60" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Jank: NO_JANK' 'no-jank classification'; step8_assert_contains "$O" 'Janky frame count: 0' 'no janky frames'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/fps/unstable-60" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Jank:' 'unstable jank classification'; step8_assert_contains "$O" 'Jank percentage:' 'jank percentage'; step8_assert_contains "$O" 'Jank bursts:' 'jank bursts'
O="$(FPS_DATA_ROOT="$FIXTURE_DIR/fps/heavy-jank" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'Jank: SEVERE_JANK' 'severe jank classification'; step8_assert_contains "$O" 'Janky frame count:' 'severe janky count'; step8_assert_contains "$O" 'Longest frame:' 'longest-frame label'
step8_pass 'jank classes, slow frames, percentages, bursts, and longest-frame reporting'
step8_cleanup
