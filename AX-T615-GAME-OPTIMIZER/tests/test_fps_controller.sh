#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"; F60="$FIXTURE_DIR/fps/stable-60"; FS="$FIXTURE_DIR/fps/frame-spikes"; FM="$FIXTURE_DIR/fps/missing-data"; FU="$FIXTURE_DIR/fps/unknown"; FT="$FIXTURE_DIR/frame-time/stable"
H60="$(step8_fixture_hash "$F60")"; HS="$(step8_fixture_hash "$FS")"
O="$(FPS_DATA_ROOT="$F60" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" status)"; step8_assert_contains "$O" 'FPS source: MEASURED' 'single FPS source is measured/derived distinction'; step8_assert_contains "$O" 'Average FPS: 60.00' 'average FPS'; step8_assert_contains "$O" 'FPS P95:' 'FPS p95'; step8_assert_contains "$O" 'Frame-time P99:' 'frame-time p99'; step8_assert_contains "$O" 'No FPS values were fabricated' 'no-fake-FPS marker'
O="$(FPS_DATA_ROOT="$FS" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze --package com.example.game)"; step8_assert_contains "$O" 'FPS scope: PACKAGE' 'package scope'; step8_assert_contains "$O" 'FPS P50:' 'FPS p50'; step8_assert_contains "$O" 'FPS P90:' 'FPS p90'; step8_assert_contains "$O" 'FPS P95:' 'FPS p95'; step8_assert_contains "$O" 'Frame-time spikes: 2' 'spike count'; step8_assert_contains "$O" 'Jank bursts:' 'jank bursts'; step8_assert_contains "$O" 'Frame pacing: UNSTABLE' 'unstable pacing'
O="$(FPS_DATA_ROOT="$FT" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" inspect)"; step8_assert_contains "$O" 'FPS source: DERIVED' 'frame-time derived source'; step8_assert_contains "$O" 'Average frame-time: 16.65 ms' 'derived frame-time'
O="$(FPS_DATA_ROOT="$FM" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze)"; step8_assert_contains "$O" 'FPS source: UNAVAILABLE' 'missing FPS source'; step8_assert_contains "$O" 'Average FPS: UNAVAILABLE' 'missing FPS value'; step8_assert_contains "$O" 'Frame pacing: UNKNOWN' 'missing pacing safety'
O="$(FPS_DATA_ROOT="$FU" DISPLAY_DATA_ROOT="$D60" FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-controller" analyze --package com.unknown.game)"; step8_assert_contains "$O" 'PACKAGE FPS: UNAVAILABLE' 'package unavailable marker'; step8_assert_not_contains "$O" 'Average FPS: 60' 'no fabricated 60 FPS'
O="$(FPS_DATA_ROOT="$F60" DISPLAY_DATA_ROOT="$D60" FPS_MONITOR_ONCE=true FPS_LOG_FILE="$TMP_ROOT/fps.log" sh "$BIN_DIR/fps-monitor" --interval 1)"; step8_assert_contains "$O" 'AX FPS MONITOR' 'monitor wrapper'; step8_assert_contains "$O" 'Interval: 1s' 'monitor interval'
[ "$H60" = "$(step8_fixture_hash "$F60")" ] || step8_fail 'stable FPS fixture changed'; [ "$HS" = "$(step8_fixture_hash "$FS")" ] || step8_fail 'spike FPS fixture changed'
step8_pass 'FPS measurement, derived frame-time, percentiles, package scope, monitor, and no-fake-FPS safeguards'
step8_cleanup
