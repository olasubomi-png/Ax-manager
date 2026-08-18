#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
D60="$FIXTURE_DIR/display/60hz"; D90="$FIXTURE_DIR/display/90hz"; DU="$FIXTURE_DIR/display/unknown-refresh"; DM="$FIXTURE_DIR/display/multiple-modes"; DB="$FIXTURE_DIR/display/malformed-display"
H60="$(step8_fixture_hash "$D60")"; HM="$(step8_fixture_hash "$DM")"
O="$(step8_run_display "$D60" status)"; step8_assert_contains "$O" 'Resolution: 720x1600' '60Hz resolution'; step8_assert_contains "$O" 'Refresh rate: 60.0 Hz' '60Hz refresh'
O="$(step8_run_display "$D90" refresh)"; step8_assert_contains "$O" 'Refresh rate: 90.0 Hz' '90Hz refresh'
O="$(step8_run_display "$DM" modes)"; step8_assert_contains "$O" 'Supported refresh rates:' 'multiple refresh heading'; step8_assert_contains "$O" '90.0' 'multiple mode 90Hz'; step8_assert_contains "$O" '120.0' 'multiple mode 120Hz'
O="$(step8_run_display "$DU" status)"; step8_assert_contains "$O" 'Refresh rate: UNAVAILABLE' 'unknown refresh safety'
O="$(step8_run_display "$DB" inspect)"; step8_assert_contains "$O" 'Resolution: UNAVAILABLE' 'malformed resolution safety'; step8_assert_contains "$O" 'No display, SurfaceFlinger' 'display read-only marker'
O="$(DISPLAY_DATA_ROOT="$D60" AXGO_DATA_ROOT="$AXGO_DATA_ROOT" sh "$BIN_DIR/axgo" display status)"; step8_assert_contains "$O" 'AX-T615 DISPLAY STATUS' 'axgo display routing'
[ "$H60" = "$(step8_fixture_hash "$D60")" ] || step8_fail '60Hz fixture changed'; [ "$HM" = "$(step8_fixture_hash "$DM")" ] || step8_fail 'multiple-mode fixture changed'
step8_pass 'display detection, refresh, modes, unknown data, routing, and immutability'
step8_cleanup
