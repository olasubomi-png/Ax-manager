#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
DATA="$STEP9_TMP/session-data"; mkdir -p "$DATA/config"
cat > "$DATA/config/games.conf" <<'EOF'
GAME_PACKAGE=""
GAME_NAME=""
GAME_PROFILE="balanced"
GAME_ENABLED="false"
GAME_1_PACKAGE="com.example.verified"
GAME_1_NAME="Verified Fixture Game"
GAME_1_PROFILE="performance"
GAME_1_ENABLED="true"
EOF
ROOT="$STEP9_ROOT"; PROFILE_DIR="$STEP9_FIXTURES/known-game"
START="$(AXGO_ROOT="$ROOT" AXGO_DATA_ROOT="$DATA" GAME_PROFILE_DIR="$PROFILE_DIR" AXGO_FOREGROUND_PACKAGE=com.example.verified sh "$STEP9_BIN/session" start com.example.verified 2>&1 || :)"
step9_assert_contains "$START" 'GAME PROFILE SESSION START' 'session start emits Step 9 profile start report'
step9_assert_contains "$START" 'Detected package: com.example.verified' 'session start records detected package'
step9_assert_file "$DATA/runtime/gaming.state" 'existing session state remains active after start'
STATUS="$(AXGO_ROOT="$ROOT" AXGO_DATA_ROOT="$DATA" GAME_PROFILE_DIR="$PROFILE_DIR" sh "$STEP9_BIN/session" status 2>&1)"
step9_assert_contains "$STATUS" 'Gaming session: ACTIVE' 'session status remains active after sampling'
STOP="$(AXGO_ROOT="$ROOT" AXGO_DATA_ROOT="$DATA" GAME_PROFILE_DIR="$PROFILE_DIR" sh "$STEP9_BIN/session" stop 2>&1 || :)"
step9_assert_contains "$STOP" 'GAME PERFORMANCE REPORT' 'session stop emits Step 9 performance report'
step9_assert_contains "$STOP" 'Mode transitions:' 'session report includes mode transitions'
step9_assert_contains "$STOP" 'No hardware settings were changed by Step 9.' 'session report states read-only safety'
step9_assert_missing "$DATA/runtime/gaming.state" 'existing session state is cleaned after stop'
step9_assert_missing "$DATA/runtime/game-profile/session.state" 'Step 9 profile session state is cleaned after stop'
