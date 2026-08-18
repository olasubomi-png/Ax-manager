#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/memory/optimal"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-memory-session.$$"
FAILURES=0
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
mkdir -p "$TMP_ROOT/config" "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
cp "$ROOT_DIR/config/games.conf" "$TMP_ROOT/config/games.conf"
cp "$ROOT_DIR/config/profiles.conf" "$TMP_ROOT/config/profiles.conf"
ENV_COMMON="AXGO_ROOT=$ROOT_DIR AXGO_DATA_ROOT=$TMP_ROOT MEMORY_PROC_ROOT=$FIXTURE/proc MEMORY_SYS_ROOT=$FIXTURE/sys MEMORY_SWAPS_FILE=$FIXTURE/proc/swaps MEMORY_POLICY_FILE=$ROOT_DIR/config/memory-policy.json"
eval "$ENV_COMMON sh $ROOT_DIR/bin/game-db add com.example.game 'Example Game' balanced" >/dev/null 2>&1
eval "$ENV_COMMON sh $ROOT_DIR/bin/profile set performance" >/dev/null 2>&1
START_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/session start com.example.game" 2>&1)"
printf '%s\n' "$START_OUTPUT" | grep -q 'Memory session started: Example Game' && pass 'memory session captured at game start' || fail 'memory session captured at game start'
printf '%s\n' "$START_OUTPUT" | grep -q 'Gaming session started' && pass 'gaming session still starts' || fail 'gaming session still starts'
[ -f "$TMP_ROOT/runtime/memory/session.state" ] && pass 'memory runtime state exists' || fail 'memory runtime state exists'
STATUS_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/session status" 2>&1)"
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Gaming session: ACTIVE' && pass 'active session remains visible' || fail 'active session remains visible'
STOP_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/session stop" 2>&1)"
printf '%s\n' "$STOP_OUTPUT" | grep -q 'MEMORY SESSION REPORT' && pass 'memory report emitted at stop' || fail 'memory report emitted at stop'
printf '%s\n' "$STOP_OUTPUT" | grep -q 'Total RAM: 3000.0 MB' && pass 'memory report includes total RAM' || fail 'memory report includes total RAM'
printf '%s\n' "$STOP_OUTPUT" | grep -q 'ZRAM: ACTIVE' && pass 'memory report includes ZRAM' || fail 'memory report includes ZRAM'
printf '%s\n' "$STOP_OUTPUT" | grep -q 'Swap: ACTIVE' && pass 'memory report includes swap' || fail 'memory report includes swap'
printf '%s\n' "$STOP_OUTPUT" | grep -q 'Gaming session stopped' && pass 'gaming session stops' || fail 'gaming session stops'
[ ! -f "$TMP_ROOT/runtime/memory/session.state" ] && pass 'memory runtime state is cleaned up' || fail 'memory runtime state is cleaned up'
[ "$FAILURES" -eq 0 ] && { echo 'All memory session tests passed.'; exit 0; }
echo "$FAILURES memory session test(s) failed."; exit 1
