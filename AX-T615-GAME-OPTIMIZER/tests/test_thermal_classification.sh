#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/thermal"
CONTROLLER="$ROOT_DIR/bin/thermal-controller"
WORK="${TMPDIR:-/tmp}/axgo-thermal-classification.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
check() {
    OUTPUT="$(THERMAL_SYSFS_ROOT="$FIXTURE/$1" THERMAL_VIRTUAL_ROOT="$WORK/none" \
        THERMAL_DATA_ROOT="$WORK/data" sh "$CONTROLLER" dry-run)"
    printf '%s\n' "$OUTPUT" | grep -q "Detected thermal state: $2" &&
        pass "$1 classified as $2" || fail "$1 classified as $2"
}
mkdir -p "$WORK"
check cool COOL
check normal NORMAL
check warm WARM
check hot HOT
check critical CRITICAL
check unknown UNKNOWN

[ "$FAILURES" -eq 0 ] && { echo "All thermal classification tests passed."; exit 0; }
echo "$FAILURES thermal classification test(s) failed."
exit 1