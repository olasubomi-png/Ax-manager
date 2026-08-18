#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
. "$TEST_DIR/step8_test_lib.sh"
step8_setup
MODULE_ROOT="$STEP8_ROOT"; PACKAGE='com.example.game'; GAME='Example Game'
cp "$MODULE_ROOT/config/profiles.conf" "$TMP_ROOT/coord/config/profiles.conf" 2>/dev/null || :
printf '%s\n' 'GAME_PACKAGE="com.example.game"' 'GAME_NAME="Example Game"' 'GAME_PROFILE="balanced"' 'GAME_ENABLED="true"' > "$TMP_ROOT/coord/config/games.conf"
cp "$FIXTURE_DIR/display/60hz/dumpsys_display" "$TMP_ROOT/coord/dumpsys_display"
cp "$FIXTURE_DIR/fps/stable-60/fps.samples" "$TMP_ROOT/coord/fps.samples"
HCFG="$(step8_fixture_hash "$MODULE_ROOT/config")"; HREADME="$(sha256sum "$MODULE_ROOT/README.md" | awk '{print $1}')"
START="$(AXGO_ROOT="$MODULE_ROOT" AXGO_DATA_ROOT="$TMP_ROOT/coord" AXGO_FOREGROUND_PACKAGE="$PACKAGE" FPS_RUNTIME_DIR="$TMP_ROOT/coord/runtime/fps" FPS_LOG_FILE="$TMP_ROOT/fps.log" DISPLAY_LOG_FILE="$TMP_ROOT/display.log" MEMORY_PERFORMANCE_LOG="$TMP_ROOT/memory.log" THERMAL_LOG_FILE="$TMP_ROOT/thermal.log" sh "$MODULE_ROOT/bin/session" start "$PACKAGE" 2>&1 || :)"
step8_assert_contains "$START" 'FPS session started:' 'FPS session start'; step8_assert_contains "$START" 'Game: Example Game' 'game metadata'; step8_assert_contains "$START" 'Package: com.example.game' 'package metadata'
STATUS="$(AXGO_ROOT="$MODULE_ROOT" AXGO_DATA_ROOT="$TMP_ROOT/coord" AXGO_FOREGROUND_PACKAGE="$PACKAGE" FPS_RUNTIME_DIR="$TMP_ROOT/coord/runtime/fps" FPS_LOG_FILE="$TMP_ROOT/fps.log" DISPLAY_LOG_FILE="$TMP_ROOT/display.log" MEMORY_PERFORMANCE_LOG="$TMP_ROOT/memory.log" THERMAL_LOG_FILE="$TMP_ROOT/thermal.log" sh "$MODULE_ROOT/bin/session" status 2>&1 || :)"; step8_assert_contains "$STATUS" 'Gaming session: ACTIVE' 'active session'; step8_assert_contains "$STATUS" 'Package: com.example.game' 'active package'
STOP="$(AXGO_ROOT="$MODULE_ROOT" AXGO_DATA_ROOT="$TMP_ROOT/coord" AXGO_FOREGROUND_PACKAGE="$PACKAGE" FPS_RUNTIME_DIR="$TMP_ROOT/coord/runtime/fps" FPS_LOG_FILE="$TMP_ROOT/fps.log" DISPLAY_LOG_FILE="$TMP_ROOT/display.log" MEMORY_PERFORMANCE_LOG="$TMP_ROOT/memory.log" THERMAL_LOG_FILE="$TMP_ROOT/thermal.log" sh "$MODULE_ROOT/bin/session" stop 2>&1 || :)"; step8_assert_contains "$STOP" 'FPS PERFORMANCE REPORT' 'FPS performance report'; step8_assert_contains "$STOP" 'Game: Example Game' 'report game'; step8_assert_contains "$STOP" 'Average FPS:' 'report FPS'; step8_assert_contains "$STOP" 'Frame pacing:' 'report pacing'; step8_assert_contains "$STOP" 'Thermal state:' 'report thermal'; step8_assert_contains "$STOP" 'Memory state:' 'report memory'; step8_assert_file_missing "$TMP_ROOT/coord/runtime/fps/session.state"; step8_assert_file_missing "$TMP_ROOT/coord/runtime/fps/session.samples"
[ "$HCFG" = "$(step8_fixture_hash "$MODULE_ROOT/config")" ] || step8_fail 'tracked config changed'; [ "$HREADME" = "$(sha256sum "$MODULE_ROOT/README.md" | awk '{print $1}')" ] || step8_fail 'README changed during session test'
step8_pass 'FPS game-session start, status, stop report, metadata, cleanup, and preservation'
step8_cleanup
