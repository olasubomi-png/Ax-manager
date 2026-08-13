#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-game-manager.$$"
MOCK_BIN="$TMP_ROOT/mock-bin"
GAME_DB="$ROOT_DIR/bin/game-db"
MANAGER="$ROOT_DIR/bin/game-manager"
MONITOR="$ROOT_DIR/bin/game-monitor"
FAILURES=0

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

mkdir -p "$TMP_ROOT/config" "$TMP_ROOT/logs" "$TMP_ROOT/runtime" "$MOCK_BIN"
cp "$ROOT_DIR/config/games.conf" "$TMP_ROOT/config/games.conf"
cp "$ROOT_DIR/config/profiles.conf" "$TMP_ROOT/config/profiles.conf"
AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add com.example.game "Example Game" performance >/dev/null

cat > "$MOCK_BIN/dumpsys" <<'EOF'
#!/bin/sh
if [ "${MOCK_FOREGROUND:-com.example.game}" = "unknown.app" ]; then
    echo "mResumedActivity: ActivityRecord{1 u0 unknown.app/.MainActivity}"
elif [ "${MOCK_METHOD:-activity}" = "window" ] && [ "${1:-}" = "window" ]; then
    echo "mCurrentFocus=Window{1 u0 com.example.game/com.example.game.MainActivity}"
elif [ "${MOCK_METHOD:-activity}" = "window" ]; then
    exit 0
else
    echo "mResumedActivity: ActivityRecord{1 u0 com.example.game/.MainActivity}"
fi
EOF
chmod +x "$MOCK_BIN/dumpsys"

OUTPUT="$(PATH="$MOCK_BIN:$PATH" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" detect)"
printf '%s\n' "$OUTPUT" | grep -q "Foreground package: com.example.game" &&
    pass "foreground package detection" || fail "foreground package detection"
printf '%s\n' "$OUTPUT" | grep -q "Selected profile: PERFORMANCE" &&
    pass "configured game profile selection" || fail "configured game profile selection"

UNKNOWN_OUTPUT="$(PATH="$MOCK_BIN:$PATH" MOCK_FOREGROUND=unknown.app AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" detect)"
printf '%s\n' "$UNKNOWN_OUTPUT" | grep -q "Gaming optimization not activated" &&
    pass "unknown application is not optimized" || fail "unknown application is not optimized"

WINDOW_OUTPUT="$(PATH="$MOCK_BIN:$PATH" MOCK_METHOD=window AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" detect)"
printf '%s\n' "$WINDOW_OUTPUT" | grep -q "Foreground package: com.example.game" &&
    pass "window focus fallback detection" || fail "window focus fallback detection"

START_OUTPUT="$(PATH="$MOCK_BIN:$PATH" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" start)"
printf '%s\n' "$START_OUTPUT" | grep -q "GAME DETECTED" &&
    pass "game manager starts known game" || fail "game manager starts known game"

REPEAT_OUTPUT="$(PATH="$MOCK_BIN:$PATH" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" start)"
printf '%s\n' "$REPEAT_OUTPUT" | grep -q "already active" &&
    pass "repeated game start is idempotent" || fail "repeated game start is idempotent"

AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" stop >/dev/null
PATH="$MOCK_BIN:$PATH" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MONITOR" --once
STATE="$(cat "$TMP_ROOT/runtime/gaming.state" 2>/dev/null || :)"
[ "$STATE" = "active" ] && pass "monitor starts a configured game" || fail "monitor starts a configured game"

PATH="$MOCK_BIN:$PATH" MOCK_FOREGROUND=unknown.app AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MONITOR" --once
[ ! -e "$TMP_ROOT/runtime/gaming.state" ] &&
    pass "monitor stops when game leaves foreground" || fail "monitor stops when game leaves foreground"

PATH="/usr/bin:/bin" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$MANAGER" detect >/tmp/axgo-manager-missing-command.$$ 2>&1 || :
grep -q "Foreground package: UNKNOWN" /tmp/axgo-manager-missing-command.$$ &&
    pass "missing Android commands fail safely" || fail "missing Android commands fail safely"
rm -f /tmp/axgo-manager-missing-command.$$

[ "$FAILURES" -eq 0 ] && {
    echo "All game manager tests passed."
    exit 0
}
echo "$FAILURES game manager test(s) failed."
exit 1