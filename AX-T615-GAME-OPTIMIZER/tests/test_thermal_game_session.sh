#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
MODULE_ROOT="$ROOT_DIR"
SESSION="$MODULE_ROOT/bin/session"
FIXTURE="$TEST_DIR/fixtures/thermal"
WORK="${TMPDIR:-/tmp}/axgo-thermal-session.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$WORK/data/config" "$WORK/data/runtime" "$WORK/data/logs"
cat > "$WORK/data/config/games.conf" <<'EOF'
GAME_PACKAGE="com.example.game"
GAME_NAME="Example Game"
GAME_ENABLED="true"
GAME_PROFILE="performance"
EOF
cp "$MODULE_ROOT/config/profiles.conf" "$WORK/data/config/profiles.conf"
run_session() {
    AXGO_ROOT="$MODULE_ROOT" AXGO_DATA_ROOT="$WORK/data" THERMAL_DATA_ROOT="$WORK/data" \
    THERMAL_SYSFS_ROOT="$FIXTURE/normal" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" \
    CPU_DATA_ROOT="$WORK/data" CPU_SYSFS_ROOT="$WORK/no-cpu" \
        sh "$SESSION" "$@"
}
START_OUTPUT="$(run_session start com.example.game)"
printf '%s\n' "$START_OUTPUT" | grep -q "Thermal guard recommendation: BOOST" && pass "game start receives BOOST recommendation" || fail "game start receives BOOST recommendation"
printf '%s\n' "$START_OUTPUT" | grep -q "CPU changes: no CPU changes were applied" && pass "CPU apply remains safety-controlled" || fail "CPU apply remains safety-controlled"
printf '%s\n' "$START_OUTPUT" | grep -q "GPU action: NONE" && pass "game start reports GPU placeholder" || fail "game start reports GPU placeholder"
STATUS_OUTPUT="$(run_session status)"
printf '%s\n' "$STATUS_OUTPUT" | grep -q "Gaming session: ACTIVE" && pass "gaming session is active" || fail "gaming session is active"
STOP_OUTPUT="$(run_session stop)"
printf '%s\n' "$STOP_OUTPUT" | grep -q "AX-T615 THERMAL PERFORMANCE REPORT" && pass "game stop emits thermal performance report" || fail "game stop emits thermal performance report"
printf '%s\n' "$STOP_OUTPUT" | grep -q "Safety violations: 0" && pass "session report has zero safety violations" || fail "session report has zero safety violations"
printf '%s\n' "$STOP_OUTPUT" | grep -q "GPU changes: NONE" && pass "session report confirms no GPU changes" || fail "session report confirms no GPU changes"
[ -f "$WORK/data/logs/thermal.log" ] && pass "thermal log was written" || fail "thermal log was written"
[ "$FAILURES" -eq 0 ] && { echo "All thermal game-session tests passed."; exit 0; }
echo "$FAILURES thermal game-session test(s) failed."
exit 1
