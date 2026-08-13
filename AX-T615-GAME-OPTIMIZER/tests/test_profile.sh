#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-profile.$$"
PROFILE="$ROOT_DIR/bin/profile"
FAILURES=0

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

mkdir -p "$TMP_ROOT/config" "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
cp "$ROOT_DIR/config/profiles.conf" "$TMP_ROOT/config/profiles.conf"

DEFAULT_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$PROFILE" get)"
printf '%s\n' "$DEFAULT_OUTPUT" | grep -q "Current profile: BALANCED" &&
    pass "balanced fallback" || fail "balanced fallback"
printf '%s\n' "$DEFAULT_OUTPUT" | grep -q "CPU: pending Step 4" &&
    pass "hardware tuning remains pending" || fail "hardware tuning remains pending"

SET_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$PROFILE" set performance)"
printf '%s\n' "$SET_OUTPUT" | grep -q "Current profile: PERFORMANCE" &&
    pass "set performance profile" || fail "set performance profile"

GET_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$PROFILE" get)"
printf '%s\n' "$GET_OUTPUT" | grep -q "Current profile: PERFORMANCE" &&
    pass "profile state is recoverable" || fail "profile state is recoverable"

if AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$PROFILE" set turbo >/dev/null 2>&1; then
    fail "invalid profile was accepted"
else
    pass "invalid profile rejected"
fi

[ "$FAILURES" -eq 0 ] && {
    echo "All profile tests passed."
    exit 0
}
echo "$FAILURES profile test(s) failed."
exit 1