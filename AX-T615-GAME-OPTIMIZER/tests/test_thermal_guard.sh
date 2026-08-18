#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/thermal"
GUARD="$ROOT_DIR/bin/thermal-guard"
WORK="${TMPDIR:-/tmp}/axgo-thermal-guard.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run_guard() {
    NAME="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" THERMAL_DATA_ROOT="$WORK/data" \
    THERMAL_SYSFS_ROOT="$FIXTURE/$NAME" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" \
        sh "$GUARD" "$@"
}
expect_recommendation() {
    NAME="$1"; EXPECTED="$2"
    OUTPUT="$(run_guard "$NAME" game-start "$NAME")"
    printf '%s\n' "$OUTPUT" | grep -q "Initial recommendation: $EXPECTED" && pass "$NAME recommendation is $EXPECTED" || fail "$NAME recommendation is $EXPECTED"
    printf '%s\n' "$OUTPUT" | grep -q "GPU action: NONE" && pass "$NAME GPU action is NONE" || fail "$NAME GPU action is NONE"
    STOP_OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" THERMAL_DATA_ROOT="$WORK/data" \
        THERMAL_SYSFS_ROOT="$FIXTURE/$NAME" THERMAL_VIRTUAL_ROOT="$WORK/no-virtual" sh "$GUARD" game-stop)"
    printf '%s\n' "$STOP_OUTPUT" | grep -q "Safety violations: 0" && pass "$NAME safety violations are zero" || fail "$NAME safety violations are zero"
}
mkdir -p "$WORK"
expect_recommendation optimal BOOST
expect_recommendation normal BOOST
expect_recommendation caution CONSERVATIVE
expect_recommendation throttled CONSERVATIVE
expect_recommendation critical BLOCKED
expect_recommendation unknown CONSERVATIVE
BEFORE="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
run_guard normal check >/dev/null
AFTER="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
[ "$BEFORE" = "$AFTER" ] && pass "realistic thermal fixture remains read-only" || fail "realistic thermal fixture remains read-only"
[ "$FAILURES" -eq 0 ] && { echo "All thermal guard tests passed."; exit 0; }
echo "$FAILURES thermal guard test(s) failed."
exit 1
