#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-game-db.$$"
GAME_DB="$ROOT_DIR/bin/game-db"
FAILURES=0

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
contains() { printf '%s\n' "$1" | grep -q "$2"; }

mkdir -p "$TMP_ROOT/config" "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
cp "$ROOT_DIR/config/games.conf" "$TMP_ROOT/config/games.conf"
cp "$ROOT_DIR/config/profiles.conf" "$TMP_ROOT/config/profiles.conf"

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add com.example.game "Example Game" performance; then
    pass "add valid game"
else
    fail "add valid game"
fi

LIST_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" list)"
contains "$LIST_OUTPUT" "com.example.game" && pass "list added game" || fail "list added game"

GET_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" get com.example.game)"
contains "$GET_OUTPUT" "Profile: performance" && pass "get game profile" || fail "get game profile"

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add com.example.game "Duplicate" cool >/dev/null 2>&1; then
    fail "duplicate game was accepted"
else
    pass "duplicate game rejected"
fi

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add invalid-package "Bad Game" cool >/dev/null 2>&1; then
    fail "invalid package was accepted"
else
    pass "invalid package rejected"
fi

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" add com.example.other "Bad Profile" turbo >/dev/null 2>&1; then
    fail "invalid profile was accepted"
else
    pass "invalid profile rejected"
fi

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" remove com.example.game >/dev/null; then
    pass "remove game"
else
    fail "remove game"
fi

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$GAME_DB" get com.example.game >/dev/null 2>&1; then
    fail "removed game still returned"
else
    pass "removed game unavailable"
fi

[ "$FAILURES" -eq 0 ] && {
    echo "All game database tests passed."
    exit 0
}
echo "$FAILURES game database test(s) failed."
exit 1