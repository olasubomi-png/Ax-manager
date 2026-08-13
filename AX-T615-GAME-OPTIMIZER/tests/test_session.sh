#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-session.$$"
GAME_DB="$ROOT_DIR/bin/game-db"
SESSION="$ROOT_DIR/bin/session"
FAILURES=0

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

mkdir -p "$TMP_ROOT/config" "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
cp "$ROOT_DIR/config/games.conf" "$TMP_ROOT/config/games.conf"
cp "$ROOT_DIR/config/profiles.conf" "$TMP_ROOT/config/profiles.conf"
AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add com.example.game "Example Game" balanced >/dev/null

START_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" start com.example.game)"
printf '%s\n' "$START_OUTPUT" | grep -q "Gaming session started" &&
    pass "session start" || fail "session start"
printf '%s\n' "$START_OUTPUT" | grep -q "Hardware optimization: NOT YET ENABLED" &&
    pass "session does not tune hardware" || fail "session does not tune hardware"

REPEAT_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" start com.example.game)"
printf '%s\n' "$REPEAT_OUTPUT" | grep -q "already active" &&
    pass "repeated session start is idempotent" || fail "repeated session start is idempotent"

STATUS_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" status)"
printf '%s\n' "$STATUS_OUTPUT" | grep -q "Gaming session: ACTIVE" &&
    pass "active session status" || fail "active session status"

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" start com.unknown.app >/dev/null 2>&1; then
    fail "unknown package started a session"
else
    pass "unknown package rejected"
fi

STOP_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" stop)"
printf '%s\n' "$STOP_OUTPUT" | grep -q "Restoring normal state" &&
    pass "session stop restores logical state" || fail "session stop restores logical state"

INACTIVE_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$SESSION" status)"
printf '%s\n' "$INACTIVE_OUTPUT" | grep -q "Gaming session: INACTIVE" &&
    pass "inactive session status" || fail "inactive session status"

[ "$FAILURES" -eq 0 ] && {
    echo "All session tests passed."
    exit 0
}
echo "$FAILURES session test(s) failed."
exit 1